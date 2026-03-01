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
  // True while fetchTripRecords() is in progress — guards controller's
  // _updateTripRecordsFromSync from treating the transient empty list as
  // "no active trip" and killing an in-progress trip.
  bool isSyncing = false;

  @override
  void onInit() {
    super.onInit();
    try {
      _authService = Get.find<AuthService>();
    } catch (e) {
      _authService = Get.put(AuthService());
    }

    // Load data based on auth state
    if (_authService.isLoggedIn.value) {
      serviceRecords.clear();
      tripRecords.clear();
      syncFromFirebase();
    } else if (_authService.isGuestMode.value) {
      serviceRecords.clear();
      tripRecords.clear();
      _loadGuestData();
    } else {
      serviceRecords.clear();
      tripRecords.clear();
    }

    // Listen for auth state changes
    _authService.isLoggedIn.listen((isLoggedIn) {
      if (isLoggedIn) {
        serviceRecords.clear();
        tripRecords.clear();
        // Wait for any guest→Firebase migration to finish before fetching
        Future.delayed(const Duration(milliseconds: 500), () async {
          // If migration is still running, wait for it
          while (_authService.isMigrating) {
            await Future.delayed(const Duration(milliseconds: 200));
          }
          if (_authService.isLoggedIn.value &&
              _authService.user.value != null) {
            syncFromFirebase();
          }
        });
      } else {
        serviceRecords.clear();
        tripRecords.clear();
        clearAllLocalData();
      }
    });

    // Listen for guest mode changes
    _authService.isGuestMode.listen((isGuest) {
      if (isGuest && !_authService.isLoggedIn.value) {
        serviceRecords.clear();
        tripRecords.clear();
        _loadGuestData();
      }
    });
  }

  // ========== SERVICE RECORDS ==========

  Future<void> fetchServiceRecords() async {
    try {
      isLoading.value = true;
      String userId = _authService.user.value?.uid ?? '';

      if (userId.isEmpty) {
        return;
      }
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
    } catch (e) {
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
      } catch (e) {}
    } catch (e) {
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
        await _localStorageService.deleteServiceRecord(recordId);
        serviceRecords.removeWhere((r) => r.id == recordId);
        return;
      }

      // Remove locally
      serviceRecords.removeWhere((r) => r.id == recordId);
      await _saveServiceRecordsLocally();

      try {
        // Delete from Firebase
        await _firestore.collection('service_records').doc(recordId).delete();
      } catch (e) {}
    } catch (e) {
      throw e;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _saveServiceRecordsLocally() async {
    try {
      final currentUserId = _authService.getCurrentUserId();
      if (currentUserId.isEmpty) {
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final recordsJson =
          serviceRecords.map((record) => json.encode(record.toJson())).toList();

      // Use user-specific key for data isolation
      final userSpecificKey = 'service_records_$currentUserId';
      await prefs.setStringList(userSpecificKey, recordsJson);
    } catch (e) {}
  }

  Future<void> _loadServiceRecordsLocally() async {
    try {
      final currentUserId = _authService.getCurrentUserId();
      if (currentUserId.isEmpty) {
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
    } catch (e) {
      serviceRecords.clear();
    }
  }

  // ========== TRIP RECORDS ==========

  Future<void> fetchTripRecords() async {
    try {
      isLoading.value = true;
      isSyncing = true; // guard: block _updateTripRecordsFromSync during fetch
      String userId = _authService.user.value?.uid ?? '';

      if (userId.isEmpty) {
        isSyncing = false;
        return;
      }
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
        snapshot =
            await _firestore
                .collection('trip_records')
                .where('userId', isEqualTo: userId)
                .get();
      }

      // Build list locally first, then assign in one shot so reactive
      // listeners never see an intermediate empty 'tripRecords' state.
      final fetched = <TripRecord>[];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        fetched.add(TripRecord.fromMap(data, doc.id));
      }
      fetched.sort((a, b) => b.startTime.compareTo(a.startTime));

      // Clear isSyncing BEFORE the assignment so the controller's ever
      // listener fully processes the complete, authoritative data.
      isSyncing = false;
      // Single atomic assignment — listeners see the full updated list, never empty.
      tripRecords.value = fetched;

      await _saveTripRecordsLocally();
    } catch (e) {
      isSyncing = false;
      await _loadTripRecordsLocally();
    } finally {
      isSyncing = false;
      isLoading.value = false;
    }
  }

  Future<void> addTripRecord(TripRecord record) async {
    try {
      isLoading.value = true;

      // Check if user is in guest mode
      if (_authService.isGuestMode.value && !_authService.isLoggedIn.value) {
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
        return;
      }

      if (_authService.user.value == null) {
        throw Exception('User not logged in');
      }

      // Add to local list immediately, using the SAME id the controller
      // assigned — this keeps the controller's _activeTrip.id and the
      // sync service's tripRecord id in sync throughout the Firebase round-trip.
      final tempId = record.id;
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

        // Update with Firebase ID — use the CURRENT local state, not the
        // original `record`. If stopTrip() was called while we were waiting
        // for Firebase to respond, the local entry already has isActive:false,
        // endTime, updated costEntries, etc. — we must preserve all of that.
        final index = tripRecords.indexWhere((r) => r.id == tempId);
        if (index != -1) {
          final currentRecord = tripRecords[index]; // snapshot of current state
          final firebaseRecord = TripRecord(
            id: docRef.id,
            userId: currentRecord.userId,
            startTime: currentRecord.startTime,
            endTime: currentRecord.endTime,
            duration: currentRecord.duration,
            costEntries: currentRecord.costEntries,
            vehicleType: currentRecord.vehicleType,
            isActive:
                currentRecord
                    .isActive, // preserve current state, not stale original
          );
          tripRecords[index] = firebaseRecord;
          await _saveTripRecordsLocally();

          // If the trip was stopped while we were awaiting Firebase, push
          // the stopped state to Firestore now so the document is consistent.
          if (!currentRecord.isActive) {
            try {
              await _firestore
                  .collection('trip_records')
                  .doc(docRef.id)
                  .update(firebaseRecord.toMap());
            } catch (e) {}
          }
        }
      } catch (e) {}
    } catch (e) {
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
        await _localStorageService.updateTripRecord(record);

        final index = tripRecords.indexWhere((r) => r.id == record.id);
        if (index != -1) {
          tripRecords[index] = record;
        }
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
      } catch (e) {}
    } catch (e) {
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
        await _localStorageService.deleteTripRecord(recordId);
        tripRecords.removeWhere((r) => r.id == recordId);
        return;
      }

      // Remove locally
      tripRecords.removeWhere((r) => r.id == recordId);
      await _saveTripRecordsLocally();

      try {
        // Delete from Firebase
        await _firestore.collection('trip_records').doc(recordId).delete();
      } catch (e) {}
    } catch (e) {
      throw e;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _saveTripRecordsLocally() async {
    try {
      final currentUserId = _authService.getCurrentUserId();
      if (currentUserId.isEmpty) {
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final recordsJson =
          tripRecords.map((record) => json.encode(record.toJson())).toList();

      // Use user-specific key for data isolation
      final userSpecificKey = 'trip_records_$currentUserId';
      await prefs.setStringList(userSpecificKey, recordsJson);
    } catch (e) {}
  }

  Future<void> _loadTripRecordsLocally() async {
    try {
      final currentUserId = _authService.getCurrentUserId();
      if (currentUserId.isEmpty) {
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
    } catch (e) {
      tripRecords.clear();
    }
  }

  // ========== SYNC METHODS ==========

  Future<void> syncFromFirebase() async {
    try {
      // Fetch both service and trip records in parallel.
      // Each fetch function handles its own clear+assign atomically,
      // so we don't clear here (which would fire reactive listeners and
      // kill any in-progress trip).
      await Future.wait([fetchServiceRecords(), fetchTripRecords()]);
    } catch (e) {
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
    }

    // Also clear legacy global keys for backward compatibility
    await prefs.remove('service_records');
    await prefs.remove('trip_records');
  }

  // ========== GUEST MODE SUPPORT ==========

  /// Load guest data from local storage
  Future<void> _loadGuestData() async {
    try {
      final services = await _localStorageService.loadServiceRecords();
      final trips = await _localStorageService.loadTripRecords();

      serviceRecords.value = services;
      tripRecords.value = trips;
    } catch (e) {
      serviceRecords.clear();
      tripRecords.clear();
    }
  }

  /// Migrate guest data to Firebase when user logs in
  Future<void> migrateGuestDataToFirebase(String newUserId) async {
    try {
      // Load guest data
      final guestServices = await _localStorageService.loadServiceRecords();
      final guestTrips = await _localStorageService.loadTripRecords();
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
        } catch (e) {}
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
        } catch (e) {}
      }

      // Clear guest data after migration
      await _localStorageService.clearServiceRecords();
      await _localStorageService.clearTripRecords();
    } catch (e) {}
  }
}
