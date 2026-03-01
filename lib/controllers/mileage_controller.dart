import 'dart:convert';
import 'dart:async';
import 'package:get/get.dart';
import 'package:mileage_calculator/models/fuel_entry.dart';
import 'package:mileage_calculator/models/fueling_record.dart';
import 'package:mileage_calculator/models/service_record.dart';
import 'package:mileage_calculator/models/trip_record.dart';
import 'package:mileage_calculator/services/fueling_service.dart';
import 'package:mileage_calculator/services/auth_service.dart';
import 'package:mileage_calculator/services/service_trip_sync.dart';
import 'package:mileage_calculator/services/trip_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MileageGetxController extends GetxController {
  String _selectedVehicleType = 'Bike';
  final List<String> _vehicleTypes = ['Car', 'Bike'];
  final List<FuelEntry> _fuelEntries = [];
  final List<ServiceRecord> _serviceRecords = [];
  final List<TripRecord> _tripRecords = [];
  TripRecord? _activeTrip;
  Timer? _tripTimer;
  final int _maxHistoryEntries = 10;
  // Tracks startTimes of trips explicitly stopped in this session.
  // Uses startTime (immutable) instead of trip ID (changes when Firebase assigns doc ID).
  final Set<DateTime> _locallyStoppedTripStartTimes = {};
  // Auth state subscription — stored so it can be cancelled in onClose().
  StreamSubscription<bool>? _authStateSubscription;
  // Services
  late final FuelingService _fuelingService;
  late final AuthService _authService;
  late final ServiceTripSyncService _serviceTripSync;
  late final TripNotificationService _notificationService;

  String get selectedVehicleType => _selectedVehicleType;
  List<String> get vehicleTypes => _vehicleTypes;
  List<FuelEntry> get fuelEntries => _fuelEntries;
  List<ServiceRecord> get serviceRecords => _serviceRecords;
  List<TripRecord> get tripRecords => _tripRecords;
  TripRecord? get activeTrip => _activeTrip;
  bool get isTripActive => _activeTrip != null;
  int get maxHistoryEntries => _maxHistoryEntries;

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
    _loadSavedVehicleType();
    _loadFuelEntries();
    _loadServiceRecords();
    _loadTripRecords();

    // Trigger initial update from services in case data was already loaded
    Future.delayed(Duration.zero, () {
      _updateFromFuelingService();
      _updateServiceRecordsFromSync();
      _updateTripRecordsFromSync();
    });
  }

  void _initializeServices() {
    try {
      _fuelingService = Get.find<FuelingService>();
    } catch (e) {
      _fuelingService = Get.put(FuelingService());
    }

    try {
      _authService = Get.find<AuthService>();
    } catch (e) {
      _authService = Get.put(AuthService());
    }

    try {
      _serviceTripSync = Get.find<ServiceTripSyncService>();
    } catch (e) {
      _serviceTripSync = Get.put(ServiceTripSyncService());
    }

    // Initialize notification service
    _notificationService = TripNotificationService();
    _initializeNotifications();

    // Listen to service and trip records from sync service
    ever(_serviceTripSync.serviceRecords, (_) {
      _updateServiceRecordsFromSync();
    });
    ever(_serviceTripSync.tripRecords, (_) {
      _updateTripRecordsFromSync();
    });

    // Listen for auth state changes — store subscription so we can cancel it.
    _authStateSubscription = _authService.isLoggedIn.listen((isLoggedIn) {
      if (isLoggedIn) {
        _syncWithFirebase();
      }
    });

    // Listen for fueling service changes
    ever(_fuelingService.fuelingRecords, (_) {
      _updateFromFuelingService();
    });
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
  }

  void _updateServiceRecordsFromSync() {
    _serviceRecords.clear();
    _serviceRecords.addAll(_serviceTripSync.serviceRecords);
    update();
  }

  void _updateTripRecordsFromSync() {
    _tripRecords.clear();
    _tripRecords.addAll(_serviceTripSync.tripRecords);

    // If the sync service is mid-fetch (isSyncing=true), tripRecords may be
    // in a transient state (e.g., partially populated after fetchTripRecords
    // assigned the new list). Preserve the current _activeTrip and timer
    // entirely — we'll reconcile properly once isSyncing becomes false.
    if (_serviceTripSync.isSyncing) {
      update();
      return;
    }

    final syncActiveTrip = _tripRecords.firstWhereOrNull(
      (trip) => trip.isActive,
    );

    if (syncActiveTrip != null) {
      if (_activeTrip == null) {
        // Guard: if this trip was explicitly stopped in the current session,
        // ignore stale Firebase data that still shows isActive:true.
        // Uses startTime (immutable) instead of trip ID (which changes
        // when Firebase assigns a document ID).
        if (_locallyStoppedTripStartTimes.contains(syncActiveTrip.startTime)) {
          // Proactively push the stopped state back so subsequent listeners
          // see isActive:false without waiting for Firebase.
          final idx = _tripRecords.indexWhere((t) => t.id == syncActiveTrip.id);
          if (idx != -1) {
            final stoppedCopy = TripRecord(
              id: syncActiveTrip.id,
              userId: syncActiveTrip.userId,
              startTime: syncActiveTrip.startTime,
              endTime: syncActiveTrip.endTime ?? DateTime.now(),
              duration:
                  syncActiveTrip.endTime != null
                      ? syncActiveTrip.duration
                      : DateTime.now().difference(syncActiveTrip.startTime),
              costEntries: syncActiveTrip.costEntries,
              vehicleType: syncActiveTrip.vehicleType,
              isActive: false,
            );
            _tripRecords[idx] = stoppedCopy;
            _serviceTripSync.updateTripRecord(stoppedCopy).catchError((e) {
            });
          }
        } else {
          // Restoring active trip (e.g., after app restart / auth sync).
          _activeTrip = syncActiveTrip;
          _startTripTimer();
        }
      } else if (_activeTrip!.id != syncActiveTrip.id) {
        // The trip's ID changed (controller-assigned id → Firebase document id).
        // Update the reference but keep the live duration so the display
        // doesn't flicker back to zero.
        _activeTrip = TripRecord(
          id: syncActiveTrip.id,
          userId: _activeTrip!.userId,
          startTime: _activeTrip!.startTime,
          endTime: _activeTrip!.endTime,
          duration: _activeTrip!.duration, // keep live timer duration
          costEntries: syncActiveTrip.costEntries,
          vehicleType: _activeTrip!.vehicleType,
          isActive: true,
        );
        // Mirror corrected record back into _tripRecords
        final idx = _tripRecords.indexWhere((t) => t.id == syncActiveTrip.id);
        if (idx != -1) _tripRecords[idx] = _activeTrip!;
        // Timer is already running — no need to restart
      }
      // else: same ID, timer running correctly — nothing to do
    } else {
      // No active trip in the authoritative sync list → trip was stopped
      // (either locally or from another device). Cancel the timer.
      if (_activeTrip != null) {
        _tripTimer?.cancel();
        _tripTimer = null;
        _activeTrip = null;
      }
    }

    update();
  }

  Future<void> _loadSavedVehicleType() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedVehicleType = prefs.getString('selected_vehicle_type') ?? 'Bike';
    update();
  }

  Future<void> _saveVehicleType(String vehicleType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_vehicle_type', vehicleType);
  }

  Future<void> _loadFuelEntries() async {
    // CRITICAL: Always clear fuel entries on init
    // Never load from SharedPreferences - it may contain other users' data
    // Data will be populated via _updateFromFuelingService after Firebase sync
    _fuelEntries.clear();

    if (_authService.isLoggedIn.value && _authService.user.value != null) {
      // Data will be loaded via _updateFromFuelingService after Firebase sync
    } else if (_authService.isGuestMode.value) {
      // Trigger update from FuelingService for guest data
      _updateFromFuelingService();
    } else {
    }

    update();
  }

  Future<void> _saveFuelEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson =
        _fuelEntries.map((entry) => json.encode(entry.toJson())).toList();

    await prefs.setStringList('fuel_entries', entriesJson);

    // Removed pending sync logic - all operations are now Firebase-first
  }

  // Removed _markPendingSync and _clearPendingSync as they're no longer needed
  // All operations are now Firebase-first with automatic reactive updates

  Future<void> _syncWithFirebase() async {
    // Don't auto-sync local entries to Firebase to prevent creating unwanted data
    // Only fetch data from Firebase that already exists for this user
    try {
      await _fuelingService.fetchFuelingRecords();
      await _serviceTripSync.syncFromFirebase();
    } catch (e) {
    }
  }

  void _updateFromFuelingService() {
    // Always clear fuel entries first to prevent showing stale data
    _fuelEntries.clear();

    // Convert fueling records back to fuel entries for local display
    // Works for both authenticated users and guest mode
    if (_fuelingService.fuelingRecords.isNotEmpty) {
      final currentUserId = _authService.getCurrentUserId();
      if (currentUserId.isEmpty) {
        update();
        return;
      }

      // Filter records to ensure only current user's data is shown
      final userRecords =
          _fuelingService.fuelingRecords
              .where((record) => record.userId == currentUserId)
              .toList();
      for (var record in userRecords) {
        final fuelEntry = FuelEntry(
          id: record.id ?? '',
          date: record.date,
          odometer: record.odometer,
          fuelAmount: record.liters,
          fuelCost: record.cost,
          vehicleType: _mapVehicleId(record.vehicleId),
        );
        _fuelEntries.add(fuelEntry);
      }

      _fuelEntries.sort((a, b) => b.date.compareTo(a.date));
      _saveFuelEntries();
      update();
    } else {
      _saveFuelEntries();
      update();
    }
  }

  String _mapVehicleId(String vehicleId) {
    switch (vehicleId.toLowerCase()) {
      case 'car':
      case 'default-vehicle':
        return 'Car';
      case 'bike':
        return 'Bike';
      default:
        return 'Car';
    }
  }

  List<FuelEntry> get filteredEntries {
    return _fuelEntries
        .where((entry) => entry.vehicleType == _selectedVehicleType)
        .toList();
  }

  void updateSelectedVehicleType(String newSelection) {
    _selectedVehicleType = newSelection;
    _saveVehicleType(_selectedVehicleType);
    update();
  }

  void addFuelEntry(
    DateTime date,
    double odometer,
    double fuelAmount,
    String vehicleType,
    double fuelCost,
  ) async {
    // Get current user ID (works for both authenticated and guest mode)
    final currentUserId = _authService.getCurrentUserId();

    if (currentUserId.isEmpty) {
      return;
    }

    try {
      final fuelingRecord = FuelingRecord(
        userId: currentUserId,
        date: date,
        liters: fuelAmount,
        cost: fuelCost,
        odometer: odometer,
        notes: 'Added from mobile app',
        vehicleId: vehicleType.toLowerCase(),
      );
      await _fuelingService.addFuelingRecord(fuelingRecord);
      // The UI will update automatically via _updateFromFuelingService listener
    } catch (e) {
      throw e;
    }
  }

  void updateFuelEntry(
    int index,
    DateTime date,
    double odometer,
    double fuelAmount,
    double fuelCost,
  ) async {
    // Get current user ID (works for both authenticated and guest mode)
    final currentUserId = _authService.getCurrentUserId();

    if (currentUserId.isEmpty) {
      return;
    }

    final vehicleType = filteredEntries[index].vehicleType;
    final originalEntry = filteredEntries[index];

    if (originalEntry.id.isNotEmpty) {
      try {
        final fuelingRecord = FuelingRecord(
          id: originalEntry.id,
          userId: currentUserId,
          date: date,
          liters: fuelAmount,
          cost: fuelCost,
          odometer: odometer,
          notes: 'Updated from mobile app',
          vehicleId: vehicleType.toLowerCase(),
        );
        await _fuelingService.updateFuelingRecord(fuelingRecord);
        // The UI will update automatically via _updateFromFuelingService listener
      } catch (e) {
        throw e;
      }
    }
  }

  void deleteEntry(int index) async {
    // Get current user ID (works for both authenticated and guest mode)
    final currentUserId = _authService.getCurrentUserId();

    if (currentUserId.isEmpty) {
      return;
    }

    final originalIndex = _fuelEntries.indexOf(filteredEntries[index]);
    final entryToDelete = filteredEntries[index];

    if (originalIndex >= 0 && entryToDelete.id.isNotEmpty) {
      try {
        await _fuelingService.deleteFuelingRecord(entryToDelete.id);
        // The UI will update automatically via _updateFromFuelingService listener
      } catch (e) {
        throw e;
      }
    }
  }

  // Method to manually trigger sync (now silent)
  Future<void> syncData() async {
    if (!_authService.isLoggedIn.value) {
      // Silent failure - no snackbar notification
      return;
    }

    await _syncWithFirebase();
  }

  // Method to check if there's pending sync
  Future<bool> hasPendingSync() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_pending_sync') ?? false;
  }

  double? calculateMileage(FuelEntry currentEntry, FuelEntry? previousEntry) {
    if (previousEntry == null) return null;

    final distance = currentEntry.odometer - previousEntry.odometer;
    if (distance <= 0 || currentEntry.fuelAmount <= 0) return null;
    return distance / currentEntry.fuelAmount;
  }

  double? calculateAverageMileage() {
    double? avgMileage;
    double totalDistance = 0;
    double totalFuelUsed = 0;

    if (filteredEntries.length >= 2) {
      for (int i = 0; i < filteredEntries.length - 1; i++) {
        final currentEntry = filteredEntries[i];
        final previousEntry = filteredEntries[i + 1];

        final distance = currentEntry.odometer - previousEntry.odometer;
        if (distance > 0) {
          totalDistance += distance;
          totalFuelUsed +=
              currentEntry.fuelAmount; // Use the current entry's fuel amount
        }
      }

      if (totalFuelUsed > 0) {
        avgMileage = totalDistance / totalFuelUsed;
      }
    }
    return avgMileage;
  }

  double? calculateLatestMileage() {
    double? latestMileage;
    if (filteredEntries.length >= 2) {
      final currentEntry = filteredEntries[0];
      final previousEntry = filteredEntries[1];

      final distance = currentEntry.odometer - previousEntry.odometer;
      if (distance > 0 && currentEntry.fuelAmount > 0) {
        latestMileage =
            distance /
            currentEntry.fuelAmount; // Use current entry's fuel amount
      }
    }
    return latestMileage;
  }

  double calculateTotalDistance() {
    double totalDistance = 0;

    if (filteredEntries.length >= 2) {
      for (int i = 0; i < filteredEntries.length - 1; i++) {
        final currentEntry = filteredEntries[i];
        final previousEntry = filteredEntries[i + 1];

        final distance = currentEntry.odometer - previousEntry.odometer;
        if (distance > 0) {
          totalDistance += distance;
        }
      }
    }
    return totalDistance;
  }

  double calculateTotalFuel() {
    double totalFuel = 0;
    for (var entry in filteredEntries) {
      totalFuel += entry.fuelAmount;
    }
    return totalFuel;
  }

  double? calculateAverageFuelCost() {
    double? avgCost;
    double totalCost = 0;
    double totalFuel = 0;

    if (filteredEntries.isNotEmpty) {
      for (var entry in filteredEntries) {
        totalCost += entry.fuelCost;
        totalFuel += entry.fuelAmount;
      }

      if (totalFuel > 0) {
        avgCost = totalCost / totalFuel;
      }
    }
    return avgCost;
  }

  double? calculateLatestFuelCost() {
    if (filteredEntries.isNotEmpty) {
      final latestEntry = filteredEntries[0];
      if (latestEntry.fuelAmount > 0) {
        return latestEntry.fuelCost / latestEntry.fuelAmount;
      }
    }
    return null;
  }

  double getTotalFuel() {
    double total = 0;
    for (var entry in filteredEntries) {
      total += entry.fuelAmount;
    }
    return total;
  }

  double getTotalCost() {
    double total = 0;
    for (var entry in filteredEntries) {
      total += entry.fuelCost;
    }
    return total;
  }

  double getTotalDistance() {
    if (filteredEntries.length <= 1) return 0;

    double firstReading = filteredEntries.last.odometer;
    double lastReading = filteredEntries.first.odometer;

    return lastReading - firstReading;
  }

  double get averageMileage {
    return calculateAverageMileage() ?? 0.0;
  }

  double get lastMileage {
    return calculateLatestMileage() ?? 0.0;
  }

  double get averageFuelPrice {
    return calculateAverageFuelCost() ?? 0.0;
  }

  double get lastFuelPrice {
    return calculateLatestFuelCost() ?? 0.0;
  }

  Future<void> refreshData() async {
    await _syncWithFirebase();
  }

  // Public method to manually refresh data from fueling service
  Future<void> refreshFromFuelingService() async {
    // Refresh fueling service data first
    if (_authService.isLoggedIn.value) {
      await _fuelingService.fetchFuelingRecords();
    }

    // Update from fueling service
    _updateFromFuelingService();
  }

  void clearAllData() {
    _fuelEntries.clear();
    _saveFuelEntries();
    _serviceRecords.clear();
    _tripTimer?.cancel();
    _tripTimer = null;
    _activeTrip = null;
    _locallyStoppedTripStartTimes.clear();
    _tripRecords.clear();
  }

  // Service Records Methods
  Future<void> _loadServiceRecords() async {
    // Load from sync service instead of SharedPreferences directly
    if (_serviceTripSync.serviceRecords.isNotEmpty) {
      _serviceRecords.clear();
      _serviceRecords.addAll(_serviceTripSync.serviceRecords);
      update();
    }
  }

  void addServiceEntry(
    DateTime serviceDate,
    double odometerReading,
    double totalCost,
    String serviceType,
    String vehicleType,
  ) async {
    // Get current user ID (works for both authenticated and guest mode)
    final currentUserId = _authService.getCurrentUserId();

    if (currentUserId.isEmpty) {
      return;
    }

    final newRecord = ServiceRecord(
      id: '', // Will be assigned by Firebase or generated locally
      userId: currentUserId,
      serviceDate: serviceDate,
      odometerReading: odometerReading,
      totalCost: totalCost,
      serviceType: serviceType,
      vehicleType: vehicleType,
    );

    try {
      await _serviceTripSync.addServiceRecord(newRecord);
    } catch (e) {
    }
  }

  void deleteServiceRecord(String id) async {
    try {
      await _serviceTripSync.deleteServiceRecord(id);
    } catch (e) {
    }
  }

  List<ServiceRecord> get filteredServiceRecords {
    return _serviceRecords
        .where((record) => record.vehicleType == _selectedVehicleType)
        .toList();
  }

  // Service Statistics
  int get totalServiceCount {
    return filteredServiceRecords.length;
  }

  ServiceRecord? get nextMajorService {
    final majorServices =
        filteredServiceRecords
            .where((record) => record.serviceType == 'Major')
            .toList();
    if (majorServices.isEmpty) return null;
    return majorServices.first;
  }

  double get totalServiceCost {
    if (filteredServiceRecords.isEmpty) return 0.0;
    return filteredServiceRecords.fold(
      0.0,
      (sum, record) => sum + record.totalCost,
    );
  }

  // ========== TRIP MANAGEMENT ==========

  Future<void> _loadTripRecords() async {
    // Load from sync service instead of SharedPreferences directly
    if (_serviceTripSync.tripRecords.isNotEmpty) {
      _tripRecords.clear();
      _tripRecords.addAll(_serviceTripSync.tripRecords);
      // Restore active trip if exists
      _activeTrip = _tripRecords.firstWhereOrNull((trip) => trip.isActive);
      if (_activeTrip != null) {
        _startTripTimer();
      }
      update();
    }
  }

  void startTrip() {
    if (_activeTrip != null) return;
    // Clear stale stopped tracking — a new trip is beginning.
    _locallyStoppedTripStartTimes.clear();

    // Get current user ID (works for both authenticated and guest mode)
    final currentUserId = _authService.getCurrentUserId();

    if (currentUserId.isEmpty) {
      return;
    }

    final newTrip = TripRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: currentUserId,
      startTime: DateTime.now(),
      duration: Duration.zero,
      costEntries: [],
      vehicleType: _selectedVehicleType,
      isActive: true,
    );

    _activeTrip = newTrip;
    _tripRecords.insert(0, newTrip);
    _startTripTimer();
    update(); // UI updates IMMEDIATELY — no awaits before this

    // Fire-and-forget: show notification (errors are non-fatal)
    _notificationService
        .showTripNotification(
          tripId: newTrip.id,
          duration: newTrip.duration,
          totalCost: 0,
          costEntriesCount: 0,
          tripStartTime: newTrip.startTime,
        )
        .catchError((e) {
        });

    // Fire-and-forget: sync to Firebase
    _serviceTripSync
        .addTripRecord(newTrip)
        .then((_) {
        })
        .catchError((e) {
        });
  }

  void _startTripTimer() {
    _tripTimer?.cancel();
    _tripTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_activeTrip != null) {
        final elapsed = DateTime.now().difference(_activeTrip!.startTime);
        _activeTrip = TripRecord(
          id: _activeTrip!.id,
          userId: _activeTrip!.userId,
          startTime: _activeTrip!.startTime,
          endTime: _activeTrip!.endTime,
          duration: elapsed,
          costEntries: _activeTrip!.costEntries,
          vehicleType: _activeTrip!.vehicleType,
          isActive: _activeTrip!.isActive,
        );

        // Update notification with current trip data (fire-and-forget)
        final totalCost = _activeTrip!.costEntries.fold<double>(
          0,
          (sum, entry) => sum + entry.amount,
        );
        _notificationService
            .showTripNotification(
              tripId: _activeTrip!.id,
              duration: _activeTrip!.duration,
              totalCost: totalCost,
              costEntriesCount: _activeTrip!.costEntries.length,
              tripStartTime: _activeTrip!.startTime,
            )
            .catchError((e) {
              // Non-fatal: notification failure should not affect trip tracking
            });

        update();
      }
    });
  }

  void stopTrip() {
    if (_activeTrip == null) return;

    // ---- Synchronous state changes (no await before update()) ----

    // Capture values before nulling _activeTrip
    final tripId = _activeTrip!.id;
    final userId = _activeTrip!.userId;
    final startTime = _activeTrip!.startTime;
    final costEntries = _activeTrip!.costEntries;
    final vehicleType = _activeTrip!.vehicleType;

    // Record the trip's startTime (immutable, unlike the ID which changes
    // when Firebase assigns a document ID) so that stale sync data
    // cannot re-activate this trip.
    _locallyStoppedTripStartTimes.add(startTime);

    // Cancel timer immediately
    _tripTimer?.cancel();
    _tripTimer = null;

    final endTime = DateTime.now();
    final finalDuration = endTime.difference(startTime);

    final completedTrip = TripRecord(
      id: tripId,
      userId: userId,
      startTime: startTime,
      endTime: endTime,
      duration: finalDuration,
      costEntries: costEntries,
      vehicleType: vehicleType,
      isActive: false,
    );

    // Update the trip in the local list
    final index = _tripRecords.indexWhere((t) => t.id == tripId);
    if (index != -1) {
      _tripRecords[index] = completedTrip;
    }

    _activeTrip = null;
    update(); // UI updates IMMEDIATELY — no awaits before this

    // ---- Fire-and-forget async I/O (non-fatal errors) ----

    // Cancel notification
    _notificationService.cancelTripNotification().catchError((e) {
    });

    // Sync to Firebase
    _serviceTripSync
        .updateTripRecord(completedTrip)
        .then((_) {
        })
        .catchError((e) {
        });
  }

  void addTripCost(double amount, String description) {
    if (_activeTrip == null) return;

    final newCostEntry = TripCostEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      description: description,
      timestamp: DateTime.now(),
    );

    final updatedCostEntries = List<TripCostEntry>.from(
      _activeTrip!.costEntries,
    )..add(newCostEntry);

    _activeTrip = TripRecord(
      id: _activeTrip!.id,
      userId: _activeTrip!.userId,
      startTime: _activeTrip!.startTime,
      endTime: _activeTrip!.endTime,
      duration: _activeTrip!.duration,
      costEntries: updatedCostEntries,
      vehicleType: _activeTrip!.vehicleType,
      isActive: _activeTrip!.isActive,
    );

    // Update in the list
    final index = _tripRecords.indexWhere((t) => t.id == _activeTrip!.id);
    if (index != -1) {
      _tripRecords[index] = _activeTrip!;
    }

    // Capture current state for async operations
    final currentTrip = _activeTrip!;
    update(); // UI updates IMMEDIATELY

    // Fire-and-forget: update notification
    final totalCost = currentTrip.costEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.amount,
    );
    _notificationService
        .showTripNotification(
          tripId: currentTrip.id,
          duration: currentTrip.duration,
          totalCost: totalCost,
          costEntriesCount: currentTrip.costEntries.length,
          tripStartTime: currentTrip.startTime,
        )
        .catchError((e) {
        });

    // Fire-and-forget: sync to Firebase
    _serviceTripSync
        .updateTripRecord(currentTrip)
        .then((_) {
        })
        .catchError((e) {
        });
  }

  void deleteTripCostEntry(String costEntryId) {
    if (_activeTrip == null) return;

    final updatedCostEntries =
        _activeTrip!.costEntries
            .where((entry) => entry.id != costEntryId)
            .toList();

    _activeTrip = TripRecord(
      id: _activeTrip!.id,
      userId: _activeTrip!.userId,
      startTime: _activeTrip!.startTime,
      endTime: _activeTrip!.endTime,
      duration: _activeTrip!.duration,
      costEntries: updatedCostEntries,
      vehicleType: _activeTrip!.vehicleType,
      isActive: _activeTrip!.isActive,
    );

    // Update in the list
    final index = _tripRecords.indexWhere((t) => t.id == _activeTrip!.id);
    if (index != -1) {
      _tripRecords[index] = _activeTrip!;
    }

    // Capture for async
    final currentTrip = _activeTrip!;
    update(); // UI updates IMMEDIATELY

    // Fire-and-forget: sync to Firebase
    _serviceTripSync
        .updateTripRecord(currentTrip)
        .then((_) {
        })
        .catchError((e) {
        });
  }

  void deleteTripRecord(TripRecord trip) async {
    try {
      await _serviceTripSync.deleteTripRecord(trip.id);
    } catch (e) {
    }
  }

  List<TripRecord> get filteredTripRecords {
    return _tripRecords
        .where((record) => record.vehicleType == _selectedVehicleType)
        .toList();
  }

  List<TripRecord> get completedTrips {
    return filteredTripRecords.where((trip) => !trip.isActive).toList();
  }

  @override
  void onClose() {
    _authStateSubscription?.cancel();
    _tripTimer?.cancel();
    super.onClose();
  }
}
