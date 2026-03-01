import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mileage_calculator/models/fueling_record.dart';
import 'package:mileage_calculator/models/service_record.dart';
import 'package:mileage_calculator/models/trip_record.dart';

/// Service to handle local storage for guest users
class LocalStorageService {
  static const String _guestFuelingRecordsKey = 'guest_fueling_records';
  static const String _guestServiceRecordsKey = 'guest_service_records';
  static const String _guestTripRecordsKey = 'guest_trip_records';
  static const String _guestUserIdKey = 'guest_user_id';

  // ========== Guest User ID Management ==========

  /// Get or create a unique guest user ID
  Future<String> getGuestUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? guestId = prefs.getString(_guestUserIdKey);

    if (guestId == null || guestId.isEmpty) {
      // Generate a unique guest ID using timestamp
      guestId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString(_guestUserIdKey, guestId);
    }

    return guestId;
  }

  /// Clear guest user ID
  Future<void> clearGuestUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestUserIdKey);
  }

  // ========== FUELING RECORDS ==========

  /// Save fueling records to local storage
  Future<void> saveFuelingRecords(List<FuelingRecord> records) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData =
          records.map((record) => jsonEncode(record.toJson())).toList();
      await prefs.setStringList(_guestFuelingRecordsKey, jsonData);
    } catch (e) {
      rethrow;
    }
  }

  /// Load fueling records from local storage
  Future<List<FuelingRecord>> loadFuelingRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getStringList(_guestFuelingRecordsKey) ?? [];

      final records =
          jsonData.map((jsonStr) {
            final jsonMap = json.decode(jsonStr) as Map<String, dynamic>;
            return FuelingRecord.fromJson(jsonMap);
          }).toList();
      return records;
    } catch (e) {
      return [];
    }
  }

  /// Add a single fueling record
  Future<void> addFuelingRecord(FuelingRecord record) async {
    final records = await loadFuelingRecords();
    records.insert(0, record);
    await saveFuelingRecords(records);
  }

  /// Update a fueling record
  Future<void> updateFuelingRecord(FuelingRecord record) async {
    final records = await loadFuelingRecords();
    final index = records.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      records[index] = record;
      await saveFuelingRecords(records);
    }
  }

  /// Delete a fueling record
  Future<void> deleteFuelingRecord(String recordId) async {
    final records = await loadFuelingRecords();
    records.removeWhere((r) => r.id == recordId);
    await saveFuelingRecords(records);
  }

  /// Clear all fueling records
  Future<void> clearFuelingRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestFuelingRecordsKey);
  }

  // ========== SERVICE RECORDS ==========

  /// Save service records to local storage
  Future<void> saveServiceRecords(List<ServiceRecord> records) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData =
          records.map((record) => jsonEncode(record.toJson())).toList();
      await prefs.setStringList(_guestServiceRecordsKey, jsonData);
    } catch (e) {
      rethrow;
    }
  }

  /// Load service records from local storage
  Future<List<ServiceRecord>> loadServiceRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getStringList(_guestServiceRecordsKey) ?? [];

      final records =
          jsonData.map((jsonStr) {
            final jsonMap = json.decode(jsonStr) as Map<String, dynamic>;
            return ServiceRecord.fromJson(jsonMap);
          }).toList();
      return records;
    } catch (e) {
      return [];
    }
  }

  /// Add a single service record
  Future<void> addServiceRecord(ServiceRecord record) async {
    final records = await loadServiceRecords();
    records.insert(0, record);
    await saveServiceRecords(records);
  }

  /// Update a service record
  Future<void> updateServiceRecord(ServiceRecord record) async {
    final records = await loadServiceRecords();
    final index = records.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      records[index] = record;
      await saveServiceRecords(records);
    }
  }

  /// Delete a service record
  Future<void> deleteServiceRecord(String recordId) async {
    final records = await loadServiceRecords();
    records.removeWhere((r) => r.id == recordId);
    await saveServiceRecords(records);
  }

  /// Clear all service records
  Future<void> clearServiceRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestServiceRecordsKey);
  }

  // ========== TRIP RECORDS ==========

  /// Save trip records to local storage
  Future<void> saveTripRecords(List<TripRecord> records) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData =
          records.map((record) => jsonEncode(record.toJson())).toList();
      await prefs.setStringList(_guestTripRecordsKey, jsonData);
    } catch (e) {
      rethrow;
    }
  }

  /// Load trip records from local storage
  Future<List<TripRecord>> loadTripRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getStringList(_guestTripRecordsKey) ?? [];

      final records =
          jsonData.map((jsonStr) {
            final jsonMap = json.decode(jsonStr) as Map<String, dynamic>;
            return TripRecord.fromJson(jsonMap);
          }).toList();
      return records;
    } catch (e) {
      return [];
    }
  }

  /// Add a single trip record
  Future<void> addTripRecord(TripRecord record) async {
    final records = await loadTripRecords();
    records.insert(0, record);
    await saveTripRecords(records);
  }

  /// Update a trip record
  Future<void> updateTripRecord(TripRecord record) async {
    final records = await loadTripRecords();
    final index = records.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      records[index] = record;
      await saveTripRecords(records);
    }
  }

  /// Delete a trip record
  Future<void> deleteTripRecord(String recordId) async {
    final records = await loadTripRecords();
    records.removeWhere((r) => r.id == recordId);
    await saveTripRecords(records);
  }

  /// Clear all trip records
  Future<void> clearTripRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestTripRecordsKey);
  }

  // ========== CLEAR ALL DATA ==========

  /// Clear all guest user data from local storage
  Future<void> clearAllGuestData() async {
    await clearFuelingRecords();
    await clearServiceRecords();
    await clearTripRecords();
    await clearGuestUserId();
  }
}
