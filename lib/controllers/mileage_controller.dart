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
  String _selectedVehicleType = 'Car';
  final List<String> _vehicleTypes = ['Car', 'Bike'];
  final List<FuelEntry> _fuelEntries = [];
  final List<ServiceRecord> _serviceRecords = [];
  final List<TripRecord> _tripRecords = [];
  TripRecord? _activeTrip;
  Timer? _tripTimer;
  final int _maxHistoryEntries = 10;
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
      print('✅ MileageController: Found existing FuelingService');
    } catch (e) {
      print(
        '⚠️ MileageController: FuelingService not found, will be initialized by main',
      );
      _fuelingService = Get.put(FuelingService());
      print('✅ MileageController: Created new FuelingService');
    }

    try {
      _authService = Get.find<AuthService>();
      print('✅ MileageController: Found existing AuthService');
    } catch (e) {
      print(
        '⚠️ MileageController: AuthService not found, creating new instance',
      );
      _authService = Get.put(AuthService());
      print('✅ MileageController: Created new AuthService');
    }

    try {
      _serviceTripSync = Get.find<ServiceTripSyncService>();
      print('✅ MileageController: Found existing ServiceTripSyncService');
    } catch (e) {
      print(
        '⚠️ MileageController: ServiceTripSyncService not found, creating new instance',
      );
      _serviceTripSync = Get.put(ServiceTripSyncService());
      print('✅ MileageController: Created new ServiceTripSyncService');
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

    // Listen for auth state changes
    _authService.isLoggedIn.listen((isLoggedIn) {
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
    print('✅ MileageController: Initialized TripNotificationService');
  }

  void _updateServiceRecordsFromSync() {
    print('🔄 MileageController: Updating service records from sync service');
    _serviceRecords.clear();
    _serviceRecords.addAll(_serviceTripSync.serviceRecords);
    update();
  }

  void _updateTripRecordsFromSync() {
    print('🔄 MileageController: Updating trip records from sync service');
    _tripRecords.clear();
    _tripRecords.addAll(_serviceTripSync.tripRecords);
    // Restore active trip if exists
    _activeTrip = _tripRecords.firstWhereOrNull((trip) => trip.isActive);
    if (_activeTrip != null) {
      _startTripTimer();
    }
    update();
  }

  Future<void> _loadSavedVehicleType() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedVehicleType = prefs.getString('selected_vehicle_type') ?? 'Car';
    update();
  }

  Future<void> _saveVehicleType(String vehicleType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_vehicle_type', vehicleType);
  }

  Future<void> _loadFuelEntries() async {
    print('📥 MileageController: Loading fuel entries...');

    // CRITICAL: Always clear fuel entries on init
    // Never load from SharedPreferences - it may contain other users' data
    // Data will be populated via _updateFromFuelingService after Firebase sync
    _fuelEntries.clear();

    if (_authService.isLoggedIn.value && _authService.user.value != null) {
      print(
        '👤 User is logged in (${_authService.user.value!.uid}), will fetch from Firebase',
      );
      // Data will be loaded via _updateFromFuelingService after Firebase sync
    } else if (_authService.isGuestMode.value) {
      print('👤 Guest mode active, loading from FuelingService');
      // Trigger update from FuelingService for guest data
      _updateFromFuelingService();
    } else {
      print('ℹ️ User not logged in, keeping empty state');
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
    print('🔄 MileageController: _syncWithFirebase called');
    print('👤 User logged in: ${_authService.isLoggedIn.value}');

    // Don't auto-sync local entries to Firebase to prevent creating unwanted data
    // Only fetch data from Firebase that already exists for this user
    try {
      print('📥 Fetching user-specific data from Firebase...');
      await _fuelingService.fetchFuelingRecords();
      await _serviceTripSync.syncFromFirebase();
      print('✅ Firebase sync completed');
    } catch (e) {
      print('❌ Sync failed: $e');
    }
  }

  void _updateFromFuelingService() {
    print('🔄 MileageController: _updateFromFuelingService called');
    print('📊 Fueling records count: ${_fuelingService.fuelingRecords.length}');
    print('👤 User logged in: ${_authService.isLoggedIn.value}');
    print('👤 Guest mode: ${_authService.isGuestMode.value}');

    // Always clear fuel entries first to prevent showing stale data
    _fuelEntries.clear();

    // Convert fueling records back to fuel entries for local display
    // Works for both authenticated users and guest mode
    if (_fuelingService.fuelingRecords.isNotEmpty) {
      final currentUserId = _authService.getCurrentUserId();
      print('👤 Current user ID: $currentUserId');

      if (currentUserId.isEmpty) {
        print('⚠️ No user ID available');
        update();
        return;
      }

      // Filter records to ensure only current user's data is shown
      final userRecords =
          _fuelingService.fuelingRecords
              .where((record) => record.userId == currentUserId)
              .toList();

      print(
        '✅ Processing ${userRecords.length} fueling records for current user (filtered from ${_fuelingService.fuelingRecords.length} total)',
      );

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
        print(
          '➕ Added fuel entry: ${fuelEntry.vehicleType} - ${fuelEntry.fuelAmount}L',
        );
      }

      _fuelEntries.sort((a, b) => b.date.compareTo(a.date));
      print('✅ Sorted ${_fuelEntries.length} fuel entries');

      _saveFuelEntries();
      update();
      print('🎉 UI updated with new fuel entries');
    } else {
      print('ℹ️ No records to process');
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
    print('➕ MileageController: Adding fuel entry...');

    // Get current user ID (works for both authenticated and guest mode)
    final currentUserId = _authService.getCurrentUserId();

    if (currentUserId.isEmpty) {
      print('❌ Cannot add fuel entry: No user ID available');
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

      print('📤 Adding fueling record with userId: ${fuelingRecord.userId}');
      print('👤 Guest mode: ${_authService.isGuestMode.value}');
      await _fuelingService.addFuelingRecord(fuelingRecord);
      print('✅ Fuel entry added successfully');

      // The UI will update automatically via _updateFromFuelingService listener
    } catch (e) {
      print('❌ Failed to add fuel entry: $e');
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
    print('🔄 MileageController: Updating fuel entry...');

    // Get current user ID (works for both authenticated and guest mode)
    final currentUserId = _authService.getCurrentUserId();

    if (currentUserId.isEmpty) {
      print('❌ Cannot update fuel entry: No user ID available');
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

        print(
          '📤 Updating fueling record with userId: ${fuelingRecord.userId}',
        );
        print('👤 Guest mode: ${_authService.isGuestMode.value}');
        await _fuelingService.updateFuelingRecord(fuelingRecord);
        print('✅ Fuel entry updated successfully');

        // The UI will update automatically via _updateFromFuelingService listener
      } catch (e) {
        print('❌ Failed to update fuel entry: $e');
        throw e;
      }
    }
  }

  void deleteEntry(int index) async {
    print('🗑️ MileageController: Deleting fuel entry...');

    // Get current user ID (works for both authenticated and guest mode)
    final currentUserId = _authService.getCurrentUserId();

    if (currentUserId.isEmpty) {
      print('❌ Cannot delete fuel entry: No user ID available');
      return;
    }

    final originalIndex = _fuelEntries.indexOf(filteredEntries[index]);
    final entryToDelete = filteredEntries[index];

    if (originalIndex >= 0 && entryToDelete.id.isNotEmpty) {
      try {
        print('📤 Deleting fueling record: ${entryToDelete.id}');
        print('👤 Guest mode: ${_authService.isGuestMode.value}');
        await _fuelingService.deleteFuelingRecord(entryToDelete.id);
        print('✅ Fuel entry deleted successfully');

        // The UI will update automatically via _updateFromFuelingService listener
      } catch (e) {
        print('❌ Failed to delete fuel entry: $e');
        throw e;
      }
    }
  }

  // Method to manually trigger sync (now silent)
  Future<void> syncData() async {
    if (!_authService.isLoggedIn.value) {
      // Silent failure - no snackbar notification
      print('🔐 Sync skipped: User not logged in');
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
    print('🔄 Manual refresh triggered');
    await _syncWithFirebase();
  }

  // Public method to manually refresh data from fueling service
  Future<void> refreshFromFuelingService() async {
    print('🔄 MileageController: Manual refresh triggered');

    // Refresh fueling service data first
    if (_authService.isLoggedIn.value) {
      print('📥 Fetching latest data from Firebase...');
      await _fuelingService.fetchFuelingRecords();
    }

    // Update from fueling service
    _updateFromFuelingService();

    print('✅ Manual refresh completed');
  }

  void clearAllData() {
    print('🧹 Clearing controller data...');
    _fuelEntries.clear();
    _saveFuelEntries();
    _serviceRecords.clear();
    _tripTimer?.cancel();
    _activeTrip = null;
    _tripRecords.clear();
    print('✅ Controller data cleared');
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
      print('❌ Cannot add service record: No user ID available');
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
      print('👤 Guest mode: ${_authService.isGuestMode.value}');
      await _serviceTripSync.addServiceRecord(newRecord);
      print('✅ Service record added successfully');
    } catch (e) {
      print('❌ Failed to add service record: $e');
    }
  }

  void deleteServiceRecord(String id) async {
    try {
      await _serviceTripSync.deleteServiceRecord(id);
      print('✅ Service record deleted');
    } catch (e) {
      print('❌ Failed to delete service record: $e');
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

  void startTrip() async {
    if (_activeTrip != null) return;

    // Get current user ID (works for both authenticated and guest mode)
    final currentUserId = _authService.getCurrentUserId();

    if (currentUserId.isEmpty) {
      print('❌ Cannot start trip: No user ID available');
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

    // Show notification immediately with trip start time
    await _notificationService.showTripNotification(
      tripId: newTrip.id,
      duration: newTrip.duration,
      totalCost: 0,
      costEntriesCount: 0,
      tripStartTime: newTrip.startTime,
    );

    try {
      print('👤 Guest mode: ${_authService.isGuestMode.value}');
      await _serviceTripSync.addTripRecord(newTrip);
      print('✅ Trip started and saved');
    } catch (e) {
      print('⚠️ Trip started locally, sync failed: $e');
    }
    update();
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

        // Update notification with current trip data
        final totalCost = _activeTrip!.costEntries.fold<double>(
          0,
          (sum, entry) => sum + entry.amount,
        );
        _notificationService.showTripNotification(
          tripId: _activeTrip!.id,
          duration: _activeTrip!.duration,
          totalCost: totalCost,
          costEntriesCount: _activeTrip!.costEntries.length,
          tripStartTime: _activeTrip!.startTime,
        );

        update();
      }
    });
  }

  void stopTrip() async {
    if (_activeTrip == null) return;

    _tripTimer?.cancel();
    _tripTimer = null;

    // Cancel notification
    await _notificationService.cancelTripNotification();

    final endTime = DateTime.now();
    final finalDuration = endTime.difference(_activeTrip!.startTime);

    final completedTrip = TripRecord(
      id: _activeTrip!.id,
      userId: _activeTrip!.userId,
      startTime: _activeTrip!.startTime,
      endTime: endTime,
      duration: finalDuration,
      costEntries: _activeTrip!.costEntries,
      vehicleType: _activeTrip!.vehicleType,
      isActive: false,
    );

    // Update the trip in the list
    final index = _tripRecords.indexWhere((t) => t.id == _activeTrip!.id);
    if (index != -1) {
      _tripRecords[index] = completedTrip;
    }

    _activeTrip = null;

    try {
      await _serviceTripSync.updateTripRecord(completedTrip);
      print('✅ Trip stopped and synced to Firebase');
    } catch (e) {
      print('⚠️ Trip stopped locally, sync failed: $e');
    }
    update();
  }

  void addTripCost(double amount, String description) async {
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

    // Update notification with new cost
    final totalCost = _activeTrip!.costEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.amount,
    );
    await _notificationService.showTripNotification(
      tripId: _activeTrip!.id,
      duration: _activeTrip!.duration,
      totalCost: totalCost,
      costEntriesCount: _activeTrip!.costEntries.length,
      tripStartTime: _activeTrip!.startTime,
    );

    try {
      await _serviceTripSync.updateTripRecord(_activeTrip!);
      print('✅ Trip cost added and synced: ৳$amount');
    } catch (e) {
      print('⚠️ Trip cost added locally, sync failed: $e');
    }
    update();
  }

  void deleteTripCostEntry(String costEntryId) async {
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

    try {
      await _serviceTripSync.updateTripRecord(_activeTrip!);
      print('✅ Trip cost entry deleted and synced');
    } catch (e) {
      print('⚠️ Trip cost entry deleted locally, sync failed: $e');
    }
    update();
  }

  void deleteTripRecord(TripRecord trip) async {
    try {
      await _serviceTripSync.deleteTripRecord(trip.id);
      print('✅ Trip record deleted');
    } catch (e) {
      print('❌ Failed to delete trip record: $e');
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
    _tripTimer?.cancel();
    super.onClose();
  }
}
