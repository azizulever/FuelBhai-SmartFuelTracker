import 'dart:async';
import 'dart:ui';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Centralized Crashlytics service for error reporting and screen-level context.
/// Initialise once in main() via [CrashlyticsService.init], then access
/// anywhere with [CrashlyticsService.to].
class CrashlyticsService extends GetxService {
  static CrashlyticsService get to => Get.find<CrashlyticsService>();

  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  FirebaseCrashlytics get instance => _crashlytics;

  // ──────────────────── Global error-handler bootstrap ─────────────────────

  /// Call this in main() **after** Firebase.initializeApp and Get.put().
  /// It wires up Flutter, platform-level and zoned error handlers so that
  /// every unhandled exception automatically lands in Crashlytics.
  static Future<void> init() async {
    final crashlytics = FirebaseCrashlytics.instance;

    // Enable Crashlytics collection (set to !kDebugMode to disable in debug)
    await crashlytics.setCrashlyticsCollectionEnabled(true);

    // Catch Flutter framework errors (widget build failures, etc.)
    FlutterError.onError = (errorDetails) {
      crashlytics.recordFlutterFatalError(errorDetails);
    };

    // Catch asynchronous errors that escape Flutter's own error handling.
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // ──────────────────────── Screen context ─────────────────────────────────

  /// Sets the current screen as a Crashlytics custom key so every crash
  /// report tells you exactly which screen the user was on.
  Future<void> setCurrentScreen(String screenName) async {
    await _crashlytics.setCustomKey('current_screen', screenName);
    await _crashlytics.log('Screen viewed: $screenName');
  }

  // ──────────────────────── Manual error reporting ─────────────────────────

  /// Record a non-fatal error (e.g. caught exceptions you still want
  /// visibility into).
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    await _crashlytics.recordError(
      exception,
      stack,
      reason: reason ?? 'Non-fatal error',
      fatal: fatal,
    );
  }

  /// Log a breadcrumb message that will appear in the next crash report.
  Future<void> log(String message) async {
    await _crashlytics.log(message);
  }

  // ──────────────────────── User identification ───────────────────────────

  /// Tag crash reports with the current user so you can search by user.
  Future<void> setUserIdentifier(String userId) async {
    await _crashlytics.setUserIdentifier(userId);
  }

  /// Set an arbitrary key-value pair on all subsequent crash reports.
  Future<void> setCustomKey(String key, Object value) async {
    await _crashlytics.setCustomKey(key, value);
  }
}
