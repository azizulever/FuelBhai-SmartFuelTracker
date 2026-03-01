import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:mileage_calculator/models/fueling_record.dart';
import 'package:mileage_calculator/services/auth_service.dart';
import 'package:mileage_calculator/services/local_storage_service.dart';
import 'package:mileage_calculator/controllers/mileage_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FuelingService extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalStorageService _localStorageService = LocalStorageService();
  late final AuthService _authService;

  RxList<FuelingRecord> fuelingRecords = <FuelingRecord>[].obs;
  RxBool isLoading = false.obs;
  RxBool isOnline = true.obs;
  RxList<Map<String, dynamic>> pendingOperations = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize AuthService
    try {
      _authService = Get.find<AuthService>();
    } catch (e) {
      _authService = Get.put(AuthService());
    }

    // Don't load offline data on init - it may contain other users' data
    // Data will be loaded via auth state listener when user logs in
    if (_authService.isLoggedIn.value) {
      // Clear any existing data first
      fuelingRecords.clear();
      fetchFuelingRecords();
    } else if (_authService.isGuestMode.value) {
      fuelingRecords.clear();
      _loadGuestData();
    } else {
      fuelingRecords.clear();
    }

    // Listen for auth state changes to refresh records
    _authService.isLoggedIn.listen((isLoggedIn) {
      if (isLoggedIn) {
        // Clear any existing data first to prevent contamination
        fuelingRecords.clear();
        // Wait for any guest→Firebase migration to finish before fetching
        Future.delayed(const Duration(milliseconds: 500), () async {
          // If migration is still running, wait for it
          while (_authService.isMigrating) {
            await Future.delayed(const Duration(milliseconds: 200));
          }
          if (_authService.isLoggedIn.value &&
              _authService.user.value != null) {
            fetchFuelingRecords().then((_) {
              _processPendingOperations();
            });
          }
        });
      } else {
        fuelingRecords.clear();
        pendingOperations.clear();
        _clearAllLocalData();
      }
    });

    // Listen for guest mode changes
    _authService.isGuestMode.listen((isGuest) {
      if (isGuest && !_authService.isLoggedIn.value) {
        fuelingRecords.clear();
        _loadGuestData();
      }
    });
  }

  Future<void> _loadOfflineData() async {
    try {
      // Only load offline data if user is logged in
      if (!_authService.isLoggedIn.value || _authService.user.value == null) {
        return;
      }

      final currentUserId = _authService.user.value!.uid;
      final prefs = await SharedPreferences.getInstance();
      // Use user-specific key for better data isolation
      final userSpecificKey = 'offline_fueling_records_$currentUserId';
      final offlineData = prefs.getStringList(userSpecificKey) ?? [];
      if (offlineData.isNotEmpty) {
        final records =
            offlineData.map((jsonStr) {
              final jsonData = json.decode(jsonStr);
              return FuelingRecord.fromJson(jsonData);
            }).toList();

        // Double-check: Filter records for current user ONLY (safety check)
        final userSpecificRecords =
            records.where((record) => record.userId == currentUserId).toList();
        fuelingRecords.value = userSpecificRecords;
      } else {}

      // Load pending operations with user-specific key
      final pendingKey = 'pending_operations_$currentUserId';
      final pendingData = prefs.getStringList(pendingKey) ?? [];
      pendingOperations.value =
          pendingData.map((jsonStr) {
            return Map<String, dynamic>.from(json.decode(jsonStr));
          }).toList();
    } catch (e) {}
  }

  Future<void> _saveOfflineData() async {
    try {
      // Get current user ID for user-specific storage
      final currentUserId = _authService.getCurrentUserId();
      if (currentUserId.isEmpty) {
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final jsonData =
          fuelingRecords.map((record) {
            final jsonObj = record.toJson(); // Use toJson instead of toMap
            return jsonEncode(jsonObj);
          }).toList();

      // Use user-specific key for data isolation
      final userSpecificKey = 'offline_fueling_records_$currentUserId';
      await prefs.setStringList(userSpecificKey, jsonData);
    } catch (e) {}
  }

  Future<void> _savePendingOperation(Map<String, dynamic> operation) async {
    try {
      // Get current user ID for user-specific storage
      final currentUserId = _authService.getCurrentUserId();
      if (currentUserId.isEmpty) {
        return;
      }

      pendingOperations.add(operation);
      final prefs = await SharedPreferences.getInstance();
      final jsonData =
          pendingOperations.map((op) {
            return jsonEncode(op);
          }).toList();

      // Use user-specific key for data isolation
      final pendingKey = 'pending_operations_$currentUserId';
      await prefs.setStringList(pendingKey, jsonData);
    } catch (e) {}
  }

  Future<void> _clearAllLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get current user ID to clear user-specific data
      final currentUserId = _authService.getCurrentUserId();

      if (currentUserId.isNotEmpty) {
        // Clear user-specific offline records
        final userSpecificKey = 'offline_fueling_records_$currentUserId';
        await prefs.remove(userSpecificKey);
        // Clear user-specific pending operations
        final pendingKey = 'pending_operations_$currentUserId';
        await prefs.remove(pendingKey);
      }

      // Clear legacy global keys (for backward compatibility)
      await prefs.remove('offline_fueling_records');
      await prefs.remove('pending_operations');
      // Clear fuel entries from controller
      await prefs.remove('fuel_entries');
      // Clear vehicle type
      await prefs.remove('vehicle_type');
      // Clear in-memory data
      fuelingRecords.clear();
      pendingOperations.clear();
      // Clear controller data if available
      try {
        final mileageController = Get.find<MileageGetxController>();
        mileageController.clearAllData();
      } catch (e) {}
    } catch (e) {}
  }

  Future<void> _processPendingOperations() async {
    if (pendingOperations.isEmpty) return;

    try {
      final List<Map<String, dynamic>> operationsToProcess = List.from(
        pendingOperations,
      );

      for (var operation in operationsToProcess) {
        switch (operation['type']) {
          case 'add':
            await _executePendingAdd(operation);
            break;
          case 'update':
            await _executePendingUpdate(operation);
            break;
          case 'delete':
            await _executePendingDelete(operation);
            break;
        }

        pendingOperations.remove(operation);
      }

      // Clear pending operations with user-specific key
      final currentUserId = _authService.getCurrentUserId();
      if (currentUserId.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final pendingKey = 'pending_operations_$currentUserId';
        await prefs.setStringList(pendingKey, []);
      }
    } catch (e) {}
  }

  Future<void> _executePendingAdd(Map<String, dynamic> operation) async {
    try {
      final recordData = operation['data'];
      // Convert the stored data back to FuelingRecord, then to Firebase format
      final record = FuelingRecord.fromJson(recordData);
      await _firestore
          .collection('fueling_records')
          .add(record.toMap()); // Use toMap for Firebase
    } catch (e) {
      throw e;
    }
  }

  Future<void> _executePendingUpdate(Map<String, dynamic> operation) async {
    try {
      final recordId = operation['id'];
      final recordData = operation['data'];
      // Convert the stored data back to FuelingRecord, then to Firebase format
      final record = FuelingRecord.fromJson(recordData);
      await _firestore
          .collection('fueling_records')
          .doc(recordId)
          .update(record.toMap()); // Use toMap for Firebase
    } catch (e) {
      throw e;
    }
  }

  Future<void> _executePendingDelete(Map<String, dynamic> operation) async {
    try {
      final recordId = operation['id'];
      await _firestore.collection('fueling_records').doc(recordId).delete();
    } catch (e) {
      throw e;
    }
  }

  // Public method for explicit sync calls (bypasses auth listener delay)
  Future<void> forceFetchFuelingRecords() async {
    return fetchFuelingRecords();
  }

  Future<void> fetchFuelingRecords() async {
    try {
      isLoading.value = true;
      String userId = _authService.user.value?.uid ?? '';
      if (userId.isEmpty) {
        isLoading.value = false;
        return;
      }
      // Use a more efficient query - try with orderBy first, fallback if needed
      QuerySnapshot snapshot;
      try {
        snapshot =
            await _firestore
                .collection('fueling_records')
                .where('userId', isEqualTo: userId)
                .orderBy('date', descending: true)
                .get();
      } catch (e) {
        // If index doesn't exist, query without orderBy and sort locally
        snapshot =
            await _firestore
                .collection('fueling_records')
                .where('userId', isEqualTo: userId)
                .get();
      }
      // Only process documents that belong to the current user (extra safety check)
      final records =
          snapshot.docs
              .where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['userId'] == userId; // Ensure user-specific data
              })
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return FuelingRecord.fromMap(data, doc.id);
              })
              .toList();

      // Sort locally by date (descending) to ensure proper order
      records.sort((a, b) => b.date.compareTo(a.date));
      // Update reactive list
      fuelingRecords.value = records;
      // Force notify reactive listeners
      fuelingRecords.refresh();
      // Save to offline storage (local cache)
      await _saveOfflineData();
      isOnline.value = true;
    } catch (e) {
      // Check if this is a Firestore index error - handle silently
      if (e.toString().contains('requires an index')) {
        // No user-facing message - handle gracefully in background
      }

      isOnline.value = false;
      // Load from offline storage if online fetch fails
      await _loadOfflineData();
    } finally {
      isLoading.value = false;
    }
  }

  Future<String> addFuelingRecord(FuelingRecord record) async {
    try {
      isLoading.value = true;
      // Check if user is in guest mode
      if (_authService.isGuestMode.value && !_authService.isLoggedIn.value) {
        final tempId = DateTime.now().millisecondsSinceEpoch.toString();
        final guestUserId = _authService.getCurrentUserId();

        final guestRecord = FuelingRecord(
          id: tempId,
          userId: guestUserId,
          date: record.date,
          liters: record.liters,
          cost: record.cost,
          odometer: record.odometer,
          notes: record.notes,
          vehicleId: record.vehicleId,
        );

        await _localStorageService.addFuelingRecord(guestRecord);
        fuelingRecords.insert(0, guestRecord);
        fuelingRecords.sort((a, b) => b.date.compareTo(a.date));
        return tempId;
      }

      // Firebase mode (authenticated user)
      if (_authService.user.value == null) {
        throw Exception('User not logged in');
      }
      // Add to local list immediately (optimistic update)
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      final localRecord = FuelingRecord(
        id: tempId,
        userId: record.userId,
        date: record.date,
        liters: record.liters,
        cost: record.cost,
        odometer: record.odometer,
        notes: record.notes,
        vehicleId: record.vehicleId,
      );
      fuelingRecords.insert(0, localRecord);
      fuelingRecords.sort((a, b) => b.date.compareTo(a.date));
      await _saveOfflineData();
      try {
        // Try to add to Firebase
        final docRef = await _firestore
            .collection('fueling_records')
            .add(record.toMap());
        // Update local record with real ID
        final index = fuelingRecords.indexWhere((r) => r.id == tempId);
        if (index != -1) {
          fuelingRecords[index] = FuelingRecord(
            id: docRef.id,
            userId: record.userId,
            date: record.date,
            liters: record.liters,
            cost: record.cost,
            odometer: record.odometer,
            notes: record.notes,
            vehicleId: record.vehicleId,
          );
          await _saveOfflineData();
        }

        isOnline.value = true;
        return docRef.id;
      } catch (e) {
        isOnline.value = false;
        // Save as pending operation
        await _savePendingOperation({
          'type': 'add',
          'data': record.toJson(), // Use toJson for local storage
          'tempId': tempId,
        });
        return tempId;
      }
    } catch (e) {
      throw e;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateFuelingRecord(FuelingRecord record) async {
    try {
      isLoading.value = true;

      if (record.id == null) {
        throw Exception('Record ID is null');
      }

      // Check if user is in guest mode
      if (_authService.isGuestMode.value && !_authService.isLoggedIn.value) {
        await _localStorageService.updateFuelingRecord(record);

        final index = fuelingRecords.indexWhere((r) => r.id == record.id);
        if (index != -1) {
          fuelingRecords[index] = record;
        }
        return;
      }

      // Update local record immediately (optimistic update)
      final index = fuelingRecords.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        fuelingRecords[index] = record;
        await _saveOfflineData();
      }

      try {
        // Try to update in Firebase
        await _firestore
            .collection('fueling_records')
            .doc(record.id)
            .update(record.toMap());

        isOnline.value = true;
      } catch (e) {
        isOnline.value = false;

        // Save as pending operation
        await _savePendingOperation({
          'type': 'update',
          'id': record.id,
          'data': record.toJson(), // Use toJson for local storage
        });
      }
    } catch (e) {
      throw e;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteFuelingRecord(String recordId) async {
    try {
      isLoading.value = true;

      // Check if user is in guest mode
      if (_authService.isGuestMode.value && !_authService.isLoggedIn.value) {
        await _localStorageService.deleteFuelingRecord(recordId);
        fuelingRecords.removeWhere((r) => r.id == recordId);
        return;
      }

      // Remove from local list immediately (optimistic update)
      fuelingRecords.removeWhere((r) => r.id == recordId);
      await _saveOfflineData();

      try {
        // Try to delete from Firebase
        await _firestore.collection('fueling_records').doc(recordId).delete();

        isOnline.value = true;
      } catch (e) {
        isOnline.value = false;

        // Save as pending operation
        await _savePendingOperation({'type': 'delete', 'id': recordId});
      }
    } catch (e) {
      throw e;
    } finally {
      isLoading.value = false;
    }
  }

  // Method to sync local data with Firebase when user signs in
  Future<void> syncLocalDataToFirebase(
    List<Map<String, dynamic>> localRecords,
    String vehicleId,
  ) async {
    try {
      if (_authService.user.value == null) return;

      String userId = _authService.user.value!.uid;

      // Convert local records to FuelingRecord objects
      for (var record in localRecords) {
        FuelingRecord fuelingRecord = FuelingRecord(
          userId: userId,
          date: DateTime.parse(record['date'].toString()),
          liters: record['liters']?.toDouble() ?? 0.0,
          cost: record['cost']?.toDouble() ?? 0.0,
          odometer: record['odometer']?.toDouble() ?? 0.0,
          notes: record['notes'],
          vehicleId: record['vehicleId'] ?? 'default-vehicle',
        );

        await addFuelingRecord(fuelingRecord);
      }
    } catch (e) {}
  }

  // Manual sync method
  Future<void> syncPendingData() async {
    if (!_authService.isLoggedIn.value) {
      throw Exception('User not logged in');
    }

    await _processPendingOperations();
    await fetchFuelingRecords();
  }

  // Method specifically for syncing data from Firebase to offline after login
  Future<void> syncFromFirebaseToOffline() async {
    if (!_authService.isLoggedIn.value || _authService.user.value == null) {
      fuelingRecords.clear();
      return;
    }

    final currentUserId = _authService.user.value!.uid;
    try {
      fuelingRecords.clear();
      await _clearOfflineDataOnly();
      await fetchFuelingRecords();

      // Verify all records belong to current user
      final wrongUserRecords =
          fuelingRecords.where((r) => r.userId != currentUserId).length;
      if (wrongUserRecords > 0) {
        fuelingRecords.removeWhere((r) => r.userId != currentUserId);
      }

      // Force notify any listening controllers
      fuelingRecords.refresh();
    } catch (e) {
      // Don't load offline data as fallback - keep it clean
      fuelingRecords.clear();
    }
  }

  // Helper method to clear only offline data (not all local data)
  Future<void> _clearOfflineDataOnly() async {
    try {
      final currentUserId = _authService.getCurrentUserId();
      final prefs = await SharedPreferences.getInstance();

      // Clear user-specific offline data
      if (currentUserId.isNotEmpty) {
        final userSpecificKey = 'offline_fueling_records_$currentUserId';
        await prefs.remove(userSpecificKey);
      }

      // Also clear legacy global key for backward compatibility
      await prefs.remove('offline_fueling_records');

      fuelingRecords.clear();
    } catch (e) {}
  }

  // Check if there are pending operations
  bool get hasPendingOperations => pendingOperations.isNotEmpty;

  // Get offline status
  bool get isOfflineMode => !isOnline.value;

  // Public method to clear all local data (called from AuthService)
  Future<void> clearAllLocalData() async {
    await _clearAllLocalData();
  }

  // Debug method to test Firebase connection
  Future<void> testFirebaseConnection() async {
    try {
      // Test basic connectivity
      await _firestore.collection('test').doc('connection').get();
      // Test authentication
      if (_authService.user.value == null) {
        return;
      }

      final userId = _authService.user.value!.uid;
      // Test read permissions
      await _firestore
          .collection('fueling_records')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      // Test write permissions
      final writeTest = FuelingRecord(
        userId: userId,
        date: DateTime.now(),
        liters: 0.1,
        cost: 1.0,
        odometer: 0.0,
        notes: 'Firebase connection test - can be deleted',
        vehicleId: 'test',
      );

      final docRef = await _firestore
          .collection('fueling_records')
          .add(writeTest.toMap());
      // Clean up test document
      await _firestore.collection('fueling_records').doc(docRef.id).delete();
    } catch (e) {}
  }

  // ========== GUEST MODE SUPPORT ==========

  /// Load guest data from local storage
  Future<void> _loadGuestData() async {
    try {
      final records = await _localStorageService.loadFuelingRecords();
      fuelingRecords.value = records;
    } catch (e) {
      fuelingRecords.clear();
    }
  }

  /// Migrate guest data to Firebase when user logs in
  Future<void> migrateGuestDataToFirebase(String newUserId) async {
    try {
      // Load guest data
      final guestRecords = await _localStorageService.loadFuelingRecords();

      if (guestRecords.isEmpty) {
        return;
      }
      // Upload each record to Firebase with new user ID
      for (var record in guestRecords) {
        final newRecord = FuelingRecord(
          userId: newUserId,
          date: record.date,
          liters: record.liters,
          cost: record.cost,
          odometer: record.odometer,
          notes: record.notes,
          vehicleId: record.vehicleId,
        );

        try {
          await _firestore.collection('fueling_records').add(newRecord.toMap());
        } catch (e) {}
      }

      // Clear guest data after migration
      await _localStorageService.clearFuelingRecords();
    } catch (e) {}
  }
}
