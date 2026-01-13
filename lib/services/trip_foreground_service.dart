import 'package:flutter/services.dart';

/// Service to manage Android foreground service for trip tracking
/// This ensures the trip notification persists in the status bar
class TripForegroundService {
  static const MethodChannel _channel = MethodChannel(
    'fuelbhai/foreground_service',
  );

  static Future<void> startForegroundService() async {
    try {
      await _channel.invokeMethod('startForeground');
      print('✅ Foreground service started');
    } catch (e) {
      print('⚠️ Failed to start foreground service: $e');
    }
  }

  static Future<void> stopForegroundService() async {
    try {
      await _channel.invokeMethod('stopForeground');
      print('✅ Foreground service stopped');
    } catch (e) {
      print('⚠️ Failed to stop foreground service: $e');
    }
  }
}
