import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:get/get.dart';

/// Centralized analytics service for tracking screen views and user events.
/// Register once via Get.put() and use Get.find<AnalyticsService>() anywhere.
class AnalyticsService extends GetxService {
  static AnalyticsService get to => Get.find<AnalyticsService>();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalytics get analytics => _analytics;

  /// Navigator observer for automatic route-level tracking.
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ──────────────────────────── Screen tracking ────────────────────────────

  /// Log a screen view manually (useful for tab-based navigation).
  Future<void> logScreenView(String screenName, {String? screenClass}) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );
  }

  // ──────────────────────────── Auth events ────────────────────────────────

  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  Future<void> logSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  Future<void> logLogout() async {
    await _analytics.logEvent(name: 'logout');
  }

  Future<void> logGuestMode() async {
    await _analytics.logEvent(name: 'guest_mode_activated');
  }

  // ──────────────────────────── Fueling events ─────────────────────────────

  Future<void> logFuelEntry({
    required String vehicleType,
    required double amount,
    required double litres,
    double? mileage,
  }) async {
    await _analytics.logEvent(
      name: 'fuel_entry_added',
      parameters: {
        'vehicle_type': vehicleType,
        'amount': amount,
        'litres': litres,
        if (mileage != null) 'mileage': mileage,
      },
    );
  }

  Future<void> logFuelEntryDeleted() async {
    await _analytics.logEvent(name: 'fuel_entry_deleted');
  }

  // ──────────────────────────── Trip events ────────────────────────────────

  Future<void> logTripStarted() async {
    await _analytics.logEvent(name: 'trip_started');
  }

  Future<void> logTripEnded({double? distanceKm, int? durationMinutes}) async {
    await _analytics.logEvent(
      name: 'trip_ended',
      parameters: {
        if (distanceKm != null) 'distance_km': distanceKm,
        if (durationMinutes != null) 'duration_minutes': durationMinutes,
      },
    );
  }

  // ──────────────────────────── Service / maintenance events ───────────────

  Future<void> logServiceEntryAdded({required String serviceType}) async {
    await _analytics.logEvent(
      name: 'service_entry_added',
      parameters: {'service_type': serviceType},
    );
  }

  Future<void> logServiceEntryDeleted() async {
    await _analytics.logEvent(name: 'service_entry_deleted');
  }

  // ──────────────────────────── Navigation events ─────────────────────────

  Future<void> logTabChange(String tabName) async {
    await _analytics.logEvent(
      name: 'tab_changed',
      parameters: {'tab_name': tabName},
    );
    await logScreenView(tabName);
  }

  // ──────────────────────────── General purpose ────────────────────────────

  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  /// Set the user id for all subsequent events.
  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
  }

  /// Set a user property.
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }
}
