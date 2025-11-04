import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:mileage_calculator/models/fueling_record.dart';
import 'package:mileage_calculator/services/auth_service.dart';
import 'package:mileage_calculator/controllers/mileage_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FuelingService extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final AuthService _authService;

  RxList<FuelingRecord> fuelingRecords = <FuelingRecord>[].obs;
  RxBool isLoading = false.obs;
  RxBool isOnline = true.obs;
  RxList<Map<String, dynamic>> pendingOperations = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    print('🚀 FuelingService: Initializing...');

    // Initialize AuthService
    try {
      _authService = Get.find<AuthService>();
      print('✅ AuthService found successfully');
    } catch (e) {
      print('⚠️ AuthService not found, creating new instance');
      _authService = Get.put(AuthService());
      print('✅ New AuthService created');
    }

    // Load offline data first
    print('💾 Loading offline data...');
    _loadOfflineData();

    if (_authService.isLoggedIn.value) {
      print('👤 User is logged in, fetching Firebase records');
      fetchFuelingRecords();
    } else {
      print('👤 User not logged in, skipping Firebase fetch');
    }

    // Listen for auth state changes to refresh records
    print('👂 Setting up auth state listener...');
    _authService.isLoggedIn.listen((isLoggedIn) {
      print('🔄 Auth state changed: isLoggedIn = $isLoggedIn');
      if (isLoggedIn) {
        print('✅ User logged in, will sync data from Firebase');
        // Reduced delay to ensure auth state is stable but faster sync
        Future.delayed(const Duration(milliseconds: 800), () {
          if (_authService.isLoggedIn.value) {
            print('📥 Delayed sync: fetching records from Firebase');
            fetchFuelingRecords();
            _processPendingOperations();
          }
        });
      } else {
        print('❌ User logged out, clearing all data');
        _clearAllLocalData();
        fuelingRecords.clear();
        pendingOperations.clear();
      }
    });

    print('🎉 FuelingService initialization completed');
  }

  Future<void> _loadOfflineData() async {
    print('💾 Loading offline data...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final offlineData = prefs.getStringList('offline_fueling_records') ?? [];
      print('📊 Found ${offlineData.length} offline records');

      if (offlineData.isNotEmpty) {
        final records =
            offlineData.map((jsonStr) {
              print('📄 Processing offline record: $jsonStr');
              final jsonData = json.decode(jsonStr);
              return FuelingRecord.fromJson(
                jsonData,
              ); // Use fromJson instead of fromMap
            }).toList();

        // Filter records for current user if logged in
        List<FuelingRecord> userSpecificRecords = records;
        if (_authService.isLoggedIn.value && _authService.user.value != null) {
          final currentUserId = _authService.user.value!.uid;
          userSpecificRecords =
              records
                  .where((record) => record.userId == currentUserId)
                  .toList();
          print(
            '🔍 Filtered to ${userSpecificRecords.length} records for user: $currentUserId',
          );
        }

        fuelingRecords.value = userSpecificRecords;
        print('✅ Loaded ${userSpecificRecords.length} offline records');
      } else {
        print('ℹ️ No offline records found');
      }

      // Load pending operations
      final pendingData = prefs.getStringList('pending_operations') ?? [];
      print('📊 Found ${pendingData.length} pending operations');

      pendingOperations.value =
          pendingData.map((jsonStr) {
            print('📄 Processing pending operation: $jsonStr');
            return Map<String, dynamic>.from(json.decode(jsonStr));
          }).toList();

      print('✅ Loaded ${pendingOperations.length} pending operations');
    } catch (e) {
      print('❌ Error loading offline data: $e');
    }
  }

  Future<void> _saveOfflineData() async {
    print('💾 Saving offline data...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData =
          fuelingRecords.map((record) {
            final jsonObj = record.toJson(); // Use toJson instead of toMap
            print('📄 Saving record: $jsonObj');
            return jsonEncode(jsonObj);
          }).toList();

      await prefs.setStringList('offline_fueling_records', jsonData);
      print('✅ Saved ${jsonData.length} records to offline storage');
    } catch (e) {
      print('❌ Error saving offline data: $e');
    }
  }

  Future<void> _savePendingOperation(Map<String, dynamic> operation) async {
    print('📝 Saving pending operation...');
    print('📊 Operation: $operation');
    try {
      pendingOperations.add(operation);
      final prefs = await SharedPreferences.getInstance();
      final jsonData =
          pendingOperations.map((op) {
            print('📄 Saving pending op: $op');
            return jsonEncode(op);
          }).toList();

      await prefs.setStringList('pending_operations', jsonData);
      print('✅ Saved ${jsonData.length} pending operations');
    } catch (e) {
      print('❌ Error saving pending operation: $e');
    }
  }

  Future<void> _clearAllLocalData() async {
    print('🧹 Clearing all local data...');
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear offline records
      await prefs.remove('offline_fueling_records');
      print('✅ Cleared offline fueling records');

      // Clear pending operations
      await prefs.remove('pending_operations');
      print('✅ Cleared pending operations');

      // Clear fuel entries from controller
      await prefs.remove('fuel_entries');
      print('✅ Cleared fuel entries');

      // Clear vehicle type
      await prefs.remove('vehicle_type');
      print('✅ Cleared vehicle type');

      // Clear in-memory data
      fuelingRecords.clear();
      pendingOperations.clear();
      print('✅ Cleared in-memory data');

      // Clear controller data if available
      final mileageController = Get.find<MileageGetxController>();
      mileageController.clearAllData();
      print('✅ Cleared controller data');

      print('🎉 All local data cleared successfully');
    } catch (e) {
      print('❌ Error clearing local data: $e');
    }
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

      // Clear pending operations
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('pending_operations', []);
    } catch (e) {
      print('Error processing pending operations: $e');
    }
  }

  Future<void> _executePendingAdd(Map<String, dynamic> operation) async {
    try {
      final recordData = operation['data'];
      print('🔄 Executing pending add with data: $recordData');

      // Convert the stored data back to FuelingRecord, then to Firebase format
      final record = FuelingRecord.fromJson(recordData);
      await _firestore
          .collection('fueling_records')
          .add(record.toMap()); // Use toMap for Firebase
      print('✅ Pending add executed successfully');
    } catch (e) {
      print('❌ Failed to execute pending add: $e');
      throw e;
    }
  }

  Future<void> _executePendingUpdate(Map<String, dynamic> operation) async {
    try {
      final recordId = operation['id'];
      final recordData = operation['data'];
      print(
        '🔄 Executing pending update for ID: $recordId with data: $recordData',
      );

      // Convert the stored data back to FuelingRecord, then to Firebase format
      final record = FuelingRecord.fromJson(recordData);
      await _firestore
          .collection('fueling_records')
          .doc(recordId)
          .update(record.toMap()); // Use toMap for Firebase
      print('✅ Pending update executed successfully');
    } catch (e) {
      print('❌ Failed to execute pending update: $e');
      throw e;
    }
  }

  Future<void> _executePendingDelete(Map<String, dynamic> operation) async {
    try {
      final recordId = operation['id'];
      await _firestore.collection('fueling_records').doc(recordId).delete();
    } catch (e) {
      print('Failed to execute pending delete: $e');
      throw e;
    }
  }

  Future<void> fetchFuelingRecords() async {
    print('🔄 FuelingService: Starting fetchFuelingRecords');

    try {
      isLoading.value = true;
      print('⏳ Loading state set to true');

      String userId = _authService.user.value?.uid ?? '';
      print('👤 Current user ID: $userId');

      if (userId.isEmpty) {
        print('❌ User ID is empty, returning');
        return;
      }

      print('🔥 Querying Firebase collection: fueling_records');
      print('🔍 Filter: userId == $userId');

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
        print(
          '⚠️ Composite index not found, querying without orderBy and sorting locally',
        );
        snapshot =
            await _firestore
                .collection('fueling_records')
                .where('userId', isEqualTo: userId)
                .get();
      }

      print('📊 Firebase query completed');
      print('📄 Documents found: ${snapshot.docs.length}');

      // Only process documents that belong to the current user (extra safety check)
      final records =
          snapshot.docs
              .where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['userId'] == userId; // Ensure user-specific data
              })
              .map((doc) {
                print('📄 Processing document: ${doc.id}');
                final data = doc.data() as Map<String, dynamic>;
                print('📊 Document data: $data');
                return FuelingRecord.fromMap(data, doc.id);
              })
              .toList();

      // Sort locally by date (descending) to ensure proper order
      records.sort((a, b) => b.date.compareTo(a.date));

      print(
        '✅ Converted ${records.length} user-specific documents to FuelingRecord objects',
      );
      fuelingRecords.value = records;

      // Force notify reactive listeners
      fuelingRecords.refresh();

      // Save to offline storage
      print('💾 Saving to offline storage...');
      await _saveOfflineData();
      print('✅ Offline save completed');

      isOnline.value = true;
      print('🌐 Online status set to true');
    } catch (e) {
      print('❌ Firebase fetch FAILED: $e');
      print('📝 Error type: ${e.runtimeType}');
      print('📋 Error details: ${e.toString()}');

      // Check if this is a Firestore index error - handle silently
      if (e.toString().contains('requires an index')) {
        print('🔗 Firestore index required - using fallback query');
        // No user-facing message - handle gracefully in background
      }

      isOnline.value = false;
      print('🌐 Online status set to false');

      // Load from offline storage if online fetch fails
      print('💾 Loading from offline storage as fallback...');
      await _loadOfflineData();
      print('✅ Offline data loaded');
    } finally {
      isLoading.value = false;
      print('⏳ Loading state set to false');
      print('🏁 fetchFuelingRecords completed');
    }
  }

  Future<String> addFuelingRecord(FuelingRecord record) async {
    print('🔄 FuelingService: Starting addFuelingRecord');
    print('📊 Record details: ${record.toMap()}');

    try {
      isLoading.value = true;
      print('⏳ Loading state set to true');

      if (_authService.user.value == null) {
        print('❌ User not logged in - throwing exception');
        throw Exception('User not logged in');
      }

      print('✅ User is logged in: ${_authService.user.value!.uid}');

      // Add to local list immediately (optimistic update)
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      print('🔢 Generated temp ID: $tempId');

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

      print('💾 Adding to local list (optimistic update)');
      fuelingRecords.insert(0, localRecord);
      fuelingRecords.sort((a, b) => b.date.compareTo(a.date));
      await _saveOfflineData();
      print('✅ Local save completed');

      try {
        // Try to add to Firebase
        print('🔥 Attempting to save to Firebase...');
        print('🔥 Collection: fueling_records');
        print('🔥 Data to save: ${record.toMap()}');

        final docRef = await _firestore
            .collection('fueling_records')
            .add(record.toMap());
        print('🎉 Firebase save SUCCESS! Document ID: ${docRef.id}');

        // Update local record with real ID
        final index = fuelingRecords.indexWhere((r) => r.id == tempId);
        print('🔍 Looking for temp record at index: $index');

        if (index != -1) {
          print('🔄 Updating local record with Firebase ID');
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
          print('✅ Local record updated with Firebase ID');
        }

        isOnline.value = true;
        print('🌐 Online status set to true');
        print('🎯 Returning Firebase document ID: ${docRef.id}');
        return docRef.id;
      } catch (e) {
        print('❌ Firebase save FAILED: $e');
        print('📝 Error type: ${e.runtimeType}');
        print('📋 Error details: ${e.toString()}');

        isOnline.value = false;
        print('🌐 Online status set to false');

        // Save as pending operation
        print('📝 Saving as pending operation...');
        await _savePendingOperation({
          'type': 'add',
          'data': record.toJson(), // Use toJson for local storage
          'tempId': tempId,
        });
        print('✅ Pending operation saved');

        return tempId;
      }
    } catch (e) {
      print('💥 CRITICAL ERROR in addFuelingRecord: $e');
      print('📝 Error type: ${e.runtimeType}');
      print('📋 Error details: ${e.toString()}');
      throw e;
    } finally {
      isLoading.value = false;
      print('⏳ Loading state set to false');
      print('🏁 addFuelingRecord completed');
    }
  }

  Future<void> updateFuelingRecord(FuelingRecord record) async {
    try {
      isLoading.value = true;

      if (record.id == null) {
        throw Exception('Record ID is null');
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
        print('Failed to sync update with Firebase, saved locally: $e');
        isOnline.value = false;

        // Save as pending operation
        await _savePendingOperation({
          'type': 'update',
          'id': record.id,
          'data': record.toJson(), // Use toJson for local storage
        });
      }
    } catch (e) {
      print('Error updating fueling record: $e');
      throw e;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteFuelingRecord(String recordId) async {
    try {
      isLoading.value = true;

      // Remove from local list immediately (optimistic update)
      fuelingRecords.removeWhere((r) => r.id == recordId);
      await _saveOfflineData();

      try {
        // Try to delete from Firebase
        await _firestore.collection('fueling_records').doc(recordId).delete();

        isOnline.value = true;
      } catch (e) {
        print('Failed to sync delete with Firebase, removed locally: $e');
        isOnline.value = false;

        // Save as pending operation
        await _savePendingOperation({'type': 'delete', 'id': recordId});
      }
    } catch (e) {
      print('Error deleting fueling record: $e');
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
    } catch (e) {
      print('Error syncing local data to Firebase: $e');
    }
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
    print('🔄 FuelingService: Starting Firebase to offline sync...');

    if (!_authService.isLoggedIn.value) {
      print('❌ User not logged in, skipping sync');
      return;
    }

    try {
      print('🧹 Clearing existing offline data...');
      await _clearOfflineDataOnly();

      print('📥 Fetching fresh data from Firebase...');
      await fetchFuelingRecords();

      // Force notify any listening controllers
      print('🔄 Triggering reactive updates...');
      fuelingRecords.refresh();

      print('✅ Firebase to offline sync completed successfully');
    } catch (e) {
      print('❌ Error during Firebase to offline sync: $e');
      // Load any existing offline data as fallback
      await _loadOfflineData();
    }
  }

  // Helper method to clear only offline data (not all local data)
  Future<void> _clearOfflineDataOnly() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('offline_fueling_records');
      fuelingRecords.clear();
      print('✅ Offline fueling records cleared');
    } catch (e) {
      print('❌ Error clearing offline data: $e');
    }
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
    print('🔥 Testing Firebase connection...');

    try {
      // Test basic connectivity
      print('🔗 Testing basic Firebase connectivity...');
      await _firestore.collection('test').doc('connection').get();
      print('✅ Firebase connectivity test passed');

      // Test authentication
      print('🔐 Checking authentication...');
      if (_authService.user.value == null) {
        print('❌ No authenticated user');
        return;
      }

      final userId = _authService.user.value!.uid;
      print('✅ Authenticated user: $userId');

      // Test read permissions
      print('📖 Testing read permissions...');
      final readTest =
          await _firestore
              .collection('fueling_records')
              .where('userId', isEqualTo: userId)
              .limit(1)
              .get();
      print('✅ Read permissions OK - found ${readTest.docs.length} documents');

      // Test write permissions
      print('✏️ Testing write permissions...');
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
      print('✅ Write permissions OK - created document: ${docRef.id}');

      // Clean up test document
      await _firestore.collection('fueling_records').doc(docRef.id).delete();
      print('✅ Test document cleaned up');

      print('🎉 Firebase connection test completed successfully!');
    } catch (e) {
      print('❌ Firebase connection test FAILED: $e');
      print('📝 Error type: ${e.runtimeType}');
      print('📋 Error details: ${e.toString()}');
    }
  }
}
