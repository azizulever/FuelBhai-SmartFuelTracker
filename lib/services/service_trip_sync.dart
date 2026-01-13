import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:mileage_calculator/models/service_record.dart';
import 'package:mileage_calculator/models/trip_record.dart';
import 'package:mileage_calculator/services/auth_service.dart';
import 'package:mileage_calculator/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ServiceTripSyncService extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalStorageService _localStorageService = LocalStorageService();
  late final AuthService _authService;

  RxList<ServiceRecord> serviceRecords = <ServiceRecord>[].obs;
  RxList<TripRecord> tripRecords = <TripRecord>[].obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    print('🚀 ServiceTripSyncService: Initializing...');

    try {
      _authService = Get.find<AuthService>();
      print('✅ AuthService found');
    } catch (e) {
      print('⚠️ AuthService not found, creating new instance');
      _authService = Get.put(AuthService());
    }

    // Load data based on auth state
    if (_authService.isLoggedIn.value) {
      print(
        '👤 User is logged in, fetching service/trip records from Firebase',
      );
      serviceRecords.clear();
      tripRecords.clear();
      syncFromFirebase();
    } else if (_authService.isGuestMode.value) {
      print('👤 Guest mode active, loading local service/trip data');
      serviceRecords.clear();
      tripRecords.clear();
      _loadGuestData();
    } else {
      print('👤 User not logged in, ensuring empty state');
      serviceRecords.clear();
      tripRecords.clear();
    }

    // Listen for auth state changes
    _authService.isLoggedIn.listen((isLoggedIn) {
      print('🔄 ServiceTripSync: Auth state changed: isLoggedIn = $isLoggedIn');
      if (isLoggedIn) {
        print('✅ User logged in, fetching service/trip records from Firebase');
        serviceRecords.clear();
        tripRecords.clear();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_authService.isLoggedIn.value &&
              _authService.user.value != null) {
            syncFromFirebase();
          }
        });
      } else {
        print('❌ User logged out, clearing all service/trip data');
        serviceRecords.clear();
        tripRecords.clear();
        clearAllLocalData();
      }
    });

    // Listen for guest mode changes
    _authService.isGuestMode.listen((isGuest) {
      print('🔄 ServiceTripSync: Guest mode changed: isGuest = $isGuest');
      if (isGuest && !_authService.isLoggedIn.value) {
        print('👤 Guest mode activated, loading local service/trip data');
        serviceRecords.clear();
        tripRecords.clear();
        _loadGuestData();
      }
    });

    print('🎉 ServiceTripSyncService initialization completed');
  }

  // ========== SERVICE RECORDS ==========

  Future<void> fetchServiceRecords() async {
    try {
      isLoading.value = true;
      String userId = _authService.user.value?.uid ?? '';

      if (userId.isEmpty) {
        print('❌ User not logged in');
        return;
      }

      print('🔄 Fetching service records for user: $userId');

      QuerySnapshot snapshot;
      try {
        // Try with orderBy first (requires composite index)
        snapshot =
            await _firestore
                .collection('service_records')
                .where('userId', isEqualTo: userId)
                .orderBy('serviceDate', descending: true)
                .get();
      } catch (e) {
        // If index doesn't exist, query without orderBy and sort locally
        print(
          '⚠️ Composite index not found for service_records, querying without orderBy',
        );
        snapshot =
            await _firestore
                .collection('service_records')
                .where('userId', isEqualTo: userId)
                .get();
      }

      serviceRecords.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final record = ServiceRecord.fromMap(data, doc.id);
        serviceRecords.add(record);
      }

      // Sort locally by date (descending)
      serviceRecords.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));

      await _saveServiceRecordsLocally();
      print('✅ Fetched ${serviceRecords.length} service records');
    } catch (e) {
      print('❌ Error fetching service records: $e');
      await _loadServiceRecordsLocally();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addServiceRecord(ServiceRecord record) async {
    try {
      isLoading.value = true;

      // Check if user is in guest mode
      if (_authService.isGuestMode.value && !_authService.isLoggedIn.value) {
        print('👤 Guest mode: Saving service record to local storage');
        final tempId = DateTime.now().millisecondsSinceEpoch.toString();
        final guestUserId = _authService.getCurrentUserId();

        final guestRecord = ServiceRecord(
          id: tempId,
          userId: guestUserId,
          serviceDate: record.serviceDate,
          odometerReading: record.odometerReading,
          totalCost: record.totalCost,
          serviceType: record.serviceType,
          vehicleType: record.vehicleType,
        );

        await _localStorageService.addServiceRecord(guestRecord);
        serviceRecords.insert(0, guestRecord);
        serviceRecords.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));
        print('✅ Guest service record saved locally');
        return;
      }

      if (_authService.user.value == null) {
        throw Exception('User not logged in');
      }

      // Add to local list immediately
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      final localRecord = ServiceRecord(
        id: tempId,
        userId: record.userId,
        serviceDate: record.serviceDate,
        odometerReading: record.odometerReading,
        totalCost: record.totalCost,
        serviceType: record.serviceType,
        vehicleType: record.vehicleType,
      );

      serviceRecords.insert(0, localRecord);
      serviceRecords.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));
      await _saveServiceRecordsLocally();

      try {
        // Save to Firebase
        final docRef = await _firestore
            .collection('service_records')
            .add(record.toMap());

        // Update with Firebase ID
        final index = serviceRecords.indexWhere((r) => r.id == tempId);
        if (index != -1) {
          serviceRecords[index] = ServiceRecord(
            id: docRef.id,
            userId: record.userId,
            serviceDate: record.serviceDate,
            odometerReading: record.odometerReading,
            totalCost: record.totalCost,
            serviceType: record.serviceType,
            vehicleType: record.vehicleType,
          );
          await _saveServiceRecordsLocally();
        }
        print('✅ Service record saved to Firebase: ${docRef.id}');
      } catch (e) {
        print('⚠️ Failed to sync to Firebase, saved locally: $e');
      }
    } catch (e) {
      print('❌ Error adding service record: $e');
      throw e;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteServiceRecord(String recordId) async {
    try {
      isLoading.value = true;

      // Check if user is in guest mode
      if (_authService.isGuestMode.value && !_authService.isLoggedIn.value) {
        print('👤 Guest mode: Deleting service record from local storage');
        await _localStorageService.deleteServiceRecord(recordId);
        serviceRecords.removeWhere((r) => r.id == recordId);
        print('✅ Guest service record deleted locally');
        return;
      }

      // Remove locally
      serviceRecords.removeWhere((r) => r.id == recordId);
      await _saveServiceRecordsLocally();

      try {
        // Delete from Firebase
        await _firestore.collection('service_records').doc(recordId).delete();
        print('✅ Service record deleted from Firebase');
      } catch (e) {
        print('⚠️ Failed to delete from Firebase: $e');
      }
    } catch (e) {
      print('❌ Error deleting service record: $e');
      throw e;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _saveServiceRecordsLocally() async {
    try {
      final currentUserId = _authService.getCurrentUserId();
      if (currentUserId.isEmpty) {
        print('⚠️ No user ID available, skipping service records save');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final recordsJson =
          serviceRecords.map((record) => json.encode(record.toJson())).toList();

      // Use user-specific key for data isolation
      final userSpecificKey = 'service_records_$currentUserId';
      await prefs.setStringList(userSpecificKey, recordsJson);
      print(
        '✅ Saved ${recordsJson.length} service records for user: $currentUserId',
      );
    } catch (e) {
      print('❌ Error saving service records: $e');
    }
  }

  Future<void> _loadServiceRecordsLocally() async {
    try {
      final currentUserId = _authService.getCurrentUserId();
      if (currentUserId.isEmpty) {
        print('⚠️ No user ID available, skipping service records load');
        serviceRecords.clear();
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      // Use user-specific key for data isolation
      final userSpecificKey = 'service_records_$currentUserId';
      final recordsJson = prefs.getStringList(userSpecificKey) ?? [];

      serviceRecords.clear();
      for (var recordJson in recordsJson) {
        final record = ServiceRecord.fromJson(json.decode(recordJson));
        // Double-check user ID matches
        if (record.userId == currentUserId) {
          serviceRecords.add(record);
        }
      }
      serviceRecords.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));
      print(
        '✅ Loaded ${serviceRecords.length} service records for user: $currentUserId',
      );
    } catch (e) {
      print('❌ Error loading service records: $e');
      serviceRecords.clear();
    }
  }

  // ========== TRIP RECORDS ==========

  Future<void> fetchTripRecords() async {
    try {
      isLoading.value = true;
      String userId = _authService.user.value?.uid ?? '';

      if (userId.isEmpty) {
        print('❌ User not logged in');
        return;
      }

      print('🔄 Fetching trip records for user: $userId');

      QuerySnapshot snapshot;
      try {
        // Try with orderBy first (requires composite index)
        snapshot =
            await _firestore
                .collection('trip_records')
                .where('userId', isEqualTo: userId)
                .orderBy('startTime', descending: true)
                .get();
      } catch (e) {
        // If index doesn't exist, query without orderBy and sort locally
        print(
          '⚠️ Composite index not found for trip_records, querying without orderBy',
        );
        snapshot =
            await _firestore
                .collection('trip_records')
                .where('userId', isEqualTo: userId)
                .get();
      }

      tripRecords.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final record = TripRecord.fromMap(data, doc.id);
        tripRecords.add(record);
      }

      // Sort locally by startTime (descending)
      tripRecords.sort((a, b) => b.startTime.compareTo(a.startTime));

      await _saveTripRecordsLocally();
      print('✅ Fetched ${tripRecords.length} trip records');
    } catch (e) {
      print('❌ Error fetching trip records: $e');
      await _loadTripRecordsLocally();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addTripRecord(TripRecord record) async {
    try {
      isLoading.value = true;

      // Check if user is in guest mode
      if (_authService.isGuestMode.value && !_authService.isLoggedIn.value) {
        print('👤 Guest mode: Saving trip record to local storage');
        final tempId = DateTime.now().millisecondsSinceEpoch.toString();
        final guestUserId = _authService.getCurrentUserId();

        final guestRecord = TripRecord(
          id: tempId,
          userId: guestUserId,
          startTime: record.startTime,
          endTime: record.endTime,
          duration: record.duration,
          costEntries: record.costEntries,
          vehicleType: record.vehicleType,
          isActive: record.isActive,
        );

        await _localStorageService.addTripRecord(guestRecord);
        tripRecords.insert(0, guestRecord);
        tripRecords.sort((a, b) => b.startTime.compareTo(a.startTime));
        print('✅ Guest trip record saved locally');
        return;
      }

      if (_authService.user.value == null) {
        throw Exception('User not logged in');
      }

      // Add to local list immediately
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      final localRecord = TripRecord(
        id: tempId,
        userId: record.userId,
        startTime: record.startTime,
        endTime: record.endTime,
        duration: record.duration,
        costEntries: record.costEntries,
        vehicleType: record.vehicleType,
        isActive: record.isActive,
      );

      tripRecords.insert(0, localRecord);
      tripRecords.sort((a, b) => b.startTime.compareTo(a.startTime));
      await _saveTripRecordsLocally();

      try {
        // Save to Firebase
        final docRef = await _firestore
            .collection('trip_records')
            .add(record.toMap());

        // Update with Firebase ID
        final index = tripRecords.indexWhere((r) => r.id == tempId);
        if (index != -1) {
          tripRecords[index] = TripRecord(
            id: docRef.id,
            userId: record.userId,
            startTime: record.startTime,
            endTime: record.endTime,
            duration: record.duration,
            costEntries: record.costEntries,
            vehicleType: record.vehicleType,
            isActive: record.isActive,
          );
          await _saveTripRecordsLocally();
        }
        print('✅ Trip record saved to Firebase: ${docRef.id}');
      } catch (e) {
        print('⚠️ Failed to sync to Firebase, saved locally: $e');
      }
    } catch (e) {
      print('❌ Error adding trip record: $e');
      throw e;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateTripRecord(TripRecord record) async {
    try {
      isLoading.value = true;

      // Check if user is in guest mode
      if (_authService.isGuestMode.value && !_authService.isLoggedIn.value) {
        print('👤 Guest mode: Updating trip record in local storage');
        await _localStorageService.updateTripRecord(record);

        final index = tripRecords.indexWhere((r) => r.id == record.id);
        if (index != -1) {
          tripRecords[index] = record;
        }
        print('✅ Guest trip record updated locally');
        return;
      }

      // Update locally
      final index = tripRecords.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        tripRecords[index] = record;
        await _saveTripRecordsLocally();
      }

      try {
        // Update in Firebase
        await _firestore
            .collection('trip_records')
            .doc(record.id)
            .update(record.toMap());
        print('✅ Trip record updated in Firebase');
      } catch (e) {
        print('⚠️ Failed to update in Firebase: $e');
      }
    } catch (e) {
      print('❌ Error updating trip record: $e');
      throw e;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteTripRecord(String recordId) async {
    try {
      isLoading.value = true;

      // Check if user is in guest mode
      if (_authService.isGuestMode.value && !_authService.isLoggedIn.value) {
        print('👤 Guest mode: Deleting trip record from local storage');
        await _localStorageService.deleteTripRecord(recordId);
        tripRecords.removeWhere((r) => r.id == recordId);
        print('✅ Guest trip record deleted locally');
        return;
      }

      // Remove locally
      tripRecords.removeWhere((r) => r.id == recordId);
      await _saveTripRecordsLocally();

      try {
        // Delete from Firebase
        await _firestore.collection('trip_records').doc(recordId).delete();
        print('✅ Trip record deleted from Firebase');
      } catch (e) {
        print('⚠️ Failed to delete from Firebase: $e');
      }
    } catch (e) {
      print('❌ Error deleting trip record: $e');
      throw e;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _saveTripRecordsLocally() async {
    try {
      final currentUserId = _authService.getCurrentUserId();
      if (currentUserId.isEmpty) {
        print('⚠️ No user ID available, skipping trip records save');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final recordsJson =
          tripRecords.map((record) => json.encode(record.toJson())).toList();

      // Use user-specific key for data isolation
      final userSpecificKey = 'trip_records_$currentUserId';
      await prefs.setStringList(userSpecificKey, recordsJson);
      print(
        '✅ Saved ${recordsJson.length} trip records for user: $currentUserId',
      );
    } catch (e) {
      print('❌ Error saving trip records: $e');
    }
  }

  Future<void> _loadTripRecordsLocally() async {
    try {
      final currentUserId = _authService.getCurrentUserId();
      if (currentUserId.isEmpty) {
        print('⚠️ No user ID available, skipping trip records load');
        tripRecords.clear();
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      // Use user-specific key for data isolation
      final userSpecificKey = 'trip_records_$currentUserId';
      final recordsJson = prefs.getStringList(userSpecificKey) ?? [];

      tripRecords.clear();
      for (var recordJson in recordsJson) {
        final record = TripRecord.fromJson(json.decode(recordJson));
        // Double-check user ID matches
        if (record.userId == currentUserId) {
          tripRecords.add(record);
        }
      }
      tripRecords.sort((a, b) => b.startTime.compareTo(a.startTime));
      print(
        '✅ Loaded ${tripRecords.length} trip records for user: $currentUserId',
      );
    } catch (e) {
      print('❌ Error loading trip records: $e');
      tripRecords.clear();
    }
  }

  // ========== SYNC METHODS ==========

  Future<void> syncFromFirebase() async {
    print('🔄 Syncing Service and Trip records from Firebase...');

    try {
      // Clear existing data before fresh sync
      serviceRecords.clear();
      tripRecords.clear();

      // Fetch both service and trip records in parallel
      await Future.wait([fetchServiceRecords(), fetchTripRecords()]);

      // Force notify reactive listeners
      serviceRecords.refresh();
      tripRecords.refresh();

      print('✅ Service and Trip sync completed');
      print(
        '📊 Service records: ${serviceRecords.length}, Trip records: ${tripRecords.length}',
      );
    } catch (e) {
      print('❌ Error during Service/Trip sync: $e');
      // Attempt to load from local cache as fallback
      await _loadServiceRecordsLocally();
      await _loadTripRecordsLocally();
    }
  }

  Future<void> clearAllLocalData() async {
    final currentUserId = _authService.getCurrentUserId();

    serviceRecords.clear();
    tripRecords.clear();

    final prefs = await SharedPreferences.getInstance();

    // Clear user-specific keys
    if (currentUserId.isNotEmpty) {
      await prefs.remove('service_records_$currentUserId');
      await prefs.remove('trip_records_$currentUserId');
      print('✅ Cleared user-specific service/trip data for: $currentUserId');
    }

    // Also clear legacy global keys for backward compatibility
    await prefs.remove('service_records');
    await prefs.remove('trip_records');

    print('✅ Service and Trip local data cleared');
  }

  // ========== GUEST MODE SUPPORT ==========

  /// Load guest data from local storage
  Future<void> _loadGuestData() async {
    print('💾 Loading guest service/trip data from local storage...');
    try {
      final services = await _localStorageService.loadServiceRecords();
      final trips = await _localStorageService.loadTripRecords();

      serviceRecords.value = services;
      tripRecords.value = trips;

      print(
        '✅ Loaded ${services.length} service records and ${trips.length} trip records for guest',
      );
    } catch (e) {
      print('❌ Error loading guest service/trip data: $e');
      serviceRecords.clear();
      tripRecords.clear();
    }
  }

  /// Migrate guest data to Firebase when user logs in
  Future<void> migrateGuestDataToFirebase(String newUserId) async {
    print('🔄 Migrating guest service/trip data to Firebase...');
    try {
      // Load guest data
      final guestServices = await _localStorageService.loadServiceRecords();
      final guestTrips = await _localStorageService.loadTripRecords();

      print(
        '📤 Migrating ${guestServices.length} service records and ${guestTrips.length} trip records...',
      );

      // Migrate service records
      for (var record in guestServices) {
        final newRecord = ServiceRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: newUserId,
          serviceDate: record.serviceDate,
          odometerReading: record.odometerReading,
          totalCost: record.totalCost,
          serviceType: record.serviceType,
          vehicleType: record.vehicleType,
        );

        try {
          await _firestore.collection('service_records').add(newRecord.toMap());
          print('✅ Migrated service record from ${record.serviceDate}');
        } catch (e) {
          print('⚠️ Failed to migrate service record: $e');
        }
      }

      // Migrate trip records
      for (var record in guestTrips) {
        final newRecord = TripRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: newUserId,
          startTime: record.startTime,
          endTime: record.endTime,
          duration: record.duration,
          costEntries: record.costEntries,
          vehicleType: record.vehicleType,
          isActive: record.isActive,
        );

        try {
          await _firestore.collection('trip_records').add(newRecord.toMap());
          print('✅ Migrated trip record from ${record.startTime}');
        } catch (e) {
          print('⚠️ Failed to migrate trip record: $e');
        }
      }

      // Clear guest data after migration
      await _localStorageService.clearServiceRecords();
      await _localStorageService.clearTripRecords();
      print('✅ Guest service/trip data migration completed and cleared');
    } catch (e) {
      print('❌ Error migrating guest service/trip data: $e');
    }
  }
}
