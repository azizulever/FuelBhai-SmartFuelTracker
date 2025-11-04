import 'dart:convert';
import 'dart:async';
import 'package:get/get.dart';
import 'package:mileage_calculator/models/fuel_entry.dart';
import 'package:mileage_calculator/models/fueling_record.dart';
import 'package:mileage_calculator/models/service_record.dart';
import 'package:mileage_calculator/models/trip_record.dart';
import 'package:mileage_calculator/services/fueling_service.dart';
import 'package:mileage_calculator/services/auth_service.dart';
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
        '⚠️ MileageController: AuthService not found, will be initialized by main',
      );
      _authService = Get.put(AuthService());
      print('✅ MileageController: Created new AuthService');
    }

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
    final prefs = await SharedPreferences.getInstance();
    final entriesJson = prefs.getStringList('fuel_entries') ?? [];

    _fuelEntries.clear();
    for (var entryJson in entriesJson) {
      _fuelEntries.add(FuelEntry.fromJson(json.decode(entryJson)));
    }
    _fuelEntries.sort((a, b) => b.date.compareTo(a.date));
    update();
  }

  Future<void> _saveFuelEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson =
        _fuelEntries.map((entry) => json.encode(entry.toJson())).toList();

    await prefs.setStringList('fuel_entries', entriesJson);

    // Mark data as pending sync if user is logged in but offline
    if (_authService.isLoggedIn.value) {
      await _markPendingSync();
    }
  }

  Future<void> _markPendingSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_pending_sync', true);
    // Removed sync status indicator - syncing is now silent
  }

  Future<void> _clearPendingSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_pending_sync', false);
    // Removed sync status indicator - syncing is now silent
  }

  Future<void> _syncWithFirebase() async {
    // Removed sync status check - allow concurrent syncing for faster performance

    try {
      // Silent sync - no UI indicators

      // Convert local entries to fueling records and sync
      final localRecords =
          _fuelEntries
              .map(
                (entry) => {
                  'date': entry.date.toIso8601String(),
                  'liters': entry.fuelAmount,
                  'cost': entry.fuelCost,
                  'odometer': entry.odometer,
                  'notes': 'Imported from local storage',
                  'vehicleId': entry.vehicleType.toLowerCase(),
                },
              )
              .toList();

      await _fuelingService.syncLocalDataToFirebase(
        localRecords,
        'default-vehicle',
      );
      await _clearPendingSync();
    } catch (e) {
      print('Sync failed: $e');
      // Silent failure - no UI notification
    }
  }

  void _updateFromFuelingService() {
    print('🔄 MileageController: _updateFromFuelingService called');
    print('📊 Fueling records count: ${_fuelingService.fuelingRecords.length}');
    print('👤 User logged in: ${_authService.isLoggedIn.value}');

    // Convert fueling records back to fuel entries for local display
    if (_fuelingService.fuelingRecords.isNotEmpty &&
        _authService.isLoggedIn.value) {
      print(
        '✅ Processing ${_fuelingService.fuelingRecords.length} fueling records',
      );
      _fuelEntries.clear();

      for (var record in _fuelingService.fuelingRecords) {
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
      print('ℹ️ No records to process or user not logged in');
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
    // Create the entry
    final newEntry = FuelEntry(
      date: date,
      odometer: odometer,
      fuelAmount: fuelAmount,
      vehicleType: vehicleType,
      fuelCost: fuelCost,
    );

    _fuelEntries.insert(0, newEntry);
    _fuelEntries.sort((a, b) => b.date.compareTo(a.date));

    // Maintain max entries limit per vehicle type
    final carEntries =
        _fuelEntries.where((e) => e.vehicleType == 'Car').toList();
    final bikeEntries =
        _fuelEntries.where((e) => e.vehicleType == 'Bike').toList();

    if (carEntries.length > _maxHistoryEntries) {
      carEntries.sublist(_maxHistoryEntries).forEach((e) {
        _fuelEntries.remove(e);
      });
    }

    if (bikeEntries.length > _maxHistoryEntries) {
      bikeEntries.sublist(_maxHistoryEntries).forEach((e) {
        _fuelEntries.remove(e);
      });
    }

    // Save locally first (offline-first approach)
    await _saveFuelEntries();
    update();

    // Try to sync with Firebase if user is logged in
    if (_authService.isLoggedIn.value) {
      try {
        final fuelingRecord = FuelingRecord(
          userId: _authService.user.value!.uid,
          date: date,
          liters: fuelAmount,
          cost: fuelCost,
          odometer: odometer,
          notes: 'Added from mobile app',
          vehicleId: vehicleType.toLowerCase(),
        );

        await _fuelingService.addFuelingRecord(fuelingRecord);
        await _clearPendingSync();
      } catch (e) {
        print('Failed to sync with Firebase: $e');
        await _markPendingSync();
      }
    }
  }

  void updateFuelEntry(
    int index,
    DateTime date,
    double odometer,
    double fuelAmount,
    double fuelCost,
  ) async {
    final vehicleType = filteredEntries[index].vehicleType;
    final originalIndex = _fuelEntries.indexOf(filteredEntries[index]);
    final originalEntry = filteredEntries[index];

    if (originalIndex >= 0) {
      final updatedEntry = FuelEntry(
        id: originalEntry.id,
        date: date,
        odometer: odometer,
        fuelAmount: fuelAmount,
        vehicleType: vehicleType,
        fuelCost: fuelCost,
      );

      _fuelEntries[originalIndex] = updatedEntry;
      _fuelEntries.sort((a, b) => b.date.compareTo(a.date));

      // Save locally first
      await _saveFuelEntries();
      update();

      // Try to sync with Firebase if user is logged in
      if (_authService.isLoggedIn.value && originalEntry.id.isNotEmpty) {
        try {
          final fuelingRecord = FuelingRecord(
            id: originalEntry.id,
            userId: _authService.user.value!.uid,
            date: date,
            liters: fuelAmount,
            cost: fuelCost,
            odometer: odometer,
            notes: 'Updated from mobile app',
            vehicleId: vehicleType.toLowerCase(),
          );

          await _fuelingService.updateFuelingRecord(fuelingRecord);
          await _clearPendingSync();
        } catch (e) {
          print('Failed to sync update with Firebase: $e');
          await _markPendingSync();
        }
      }
    }
  }

  void deleteEntry(int index) async {
    final originalIndex = _fuelEntries.indexOf(filteredEntries[index]);
    final entryToDelete = filteredEntries[index];

    if (originalIndex >= 0) {
      _fuelEntries.removeAt(originalIndex);

      // Save locally first
      await _saveFuelEntries();
      update();

      // Try to sync with Firebase if user is logged in
      if (_authService.isLoggedIn.value && entryToDelete.id.isNotEmpty) {
        try {
          await _fuelingService.deleteFuelingRecord(entryToDelete.id);
          await _clearPendingSync();
        } catch (e) {
          print('Failed to sync deletion with Firebase: $e');
          await _markPendingSync();
        }
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
    _saveServiceRecords();
    _tripTimer?.cancel();
    _activeTrip = null;
    _tripRecords.clear();
    _saveTripRecords();
    print('✅ Controller data cleared');
  }

  // Service Records Methods
  Future<void> _loadServiceRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final recordsJson = prefs.getStringList('service_records') ?? [];

    _serviceRecords.clear();
    for (var recordJson in recordsJson) {
      _serviceRecords.add(ServiceRecord.fromJson(json.decode(recordJson)));
    }
    _serviceRecords.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));
    update();
  }

  Future<void> _saveServiceRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final recordsJson =
        _serviceRecords.map((record) => json.encode(record.toJson())).toList();

    await prefs.setStringList('service_records', recordsJson);
  }

  void addServiceEntry(
    DateTime serviceDate,
    double odometerReading,
    double totalCost,
    String serviceType,
    String vehicleType,
  ) {
    final newRecord = ServiceRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      serviceDate: serviceDate,
      odometerReading: odometerReading,
      totalCost: totalCost,
      serviceType: serviceType,
      vehicleType: vehicleType,
    );

    _serviceRecords.add(newRecord);
    _serviceRecords.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));
    _saveServiceRecords();
    update();

    print('✅ Service record added successfully');
  }

  void deleteServiceRecord(String id) {
    _serviceRecords.removeWhere((record) => record.id == id);
    _saveServiceRecords();
    update();
    print('✅ Service record deleted');
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
    final prefs = await SharedPreferences.getInstance();
    final tripRecordsJson = prefs.getStringList('trip_records') ?? [];
    _tripRecords.clear();
    for (final recordJson in tripRecordsJson) {
      final trip = TripRecord.fromJson(json.decode(recordJson));
      _tripRecords.add(trip);
      if (trip.isActive) {
        _activeTrip = trip;
        _startTripTimer();
      }
    }
    _tripRecords.sort((a, b) => b.startTime.compareTo(a.startTime));
    update();
  }

  Future<void> _saveTripRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final tripRecordsJson =
        _tripRecords.map((record) => json.encode(record.toJson())).toList();
    await prefs.setStringList('trip_records', tripRecordsJson);
  }

  void startTrip() {
    if (_activeTrip != null) return;

    final newTrip = TripRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: DateTime.now(),
      duration: Duration.zero,
      costEntries: [],
      vehicleType: _selectedVehicleType,
      isActive: true,
    );

    _activeTrip = newTrip;
    _tripRecords.insert(0, newTrip);
    _startTripTimer();
    _saveTripRecords();
    update();
    print('✅ Trip started');
  }

  void _startTripTimer() {
    _tripTimer?.cancel();
    _tripTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_activeTrip != null) {
        final elapsed = DateTime.now().difference(_activeTrip!.startTime);
        _activeTrip = TripRecord(
          id: _activeTrip!.id,
          startTime: _activeTrip!.startTime,
          endTime: _activeTrip!.endTime,
          duration: elapsed,
          costEntries: _activeTrip!.costEntries,
          vehicleType: _activeTrip!.vehicleType,
          isActive: _activeTrip!.isActive,
        );
        update();
      }
    });
  }

  void stopTrip() {
    if (_activeTrip == null) return;

    _tripTimer?.cancel();
    _tripTimer = null;

    final endTime = DateTime.now();
    final finalDuration = endTime.difference(_activeTrip!.startTime);

    final completedTrip = TripRecord(
      id: _activeTrip!.id,
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
    _saveTripRecords();
    update();
    print('✅ Trip stopped');
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

    _saveTripRecords();
    update();
    print('✅ Trip cost added: ৳$amount');
  }

  void deleteTripCostEntry(String costEntryId) {
    if (_activeTrip == null) return;

    final updatedCostEntries =
        _activeTrip!.costEntries
            .where((entry) => entry.id != costEntryId)
            .toList();

    _activeTrip = TripRecord(
      id: _activeTrip!.id,
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

    _saveTripRecords();
    update();
    print('✅ Trip cost entry deleted');
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
