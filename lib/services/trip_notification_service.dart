import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:mileage_calculator/controllers/mileage_controller.dart';
import 'package:flutter/material.dart';

class TripNotificationService {
  static final TripNotificationService _instance =
      TripNotificationService._internal();
  factory TripNotificationService() => _instance;
  TripNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'trip_tracker_channel';
  static const String _channelName = 'Trip Tracker';
  static const String _channelDescription =
      'Ongoing trip tracking notifications';
  static const int _notificationId = 1001;

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    await _createNotificationChannel();

    // Request permissions for Android 13+
    await _requestPermissions();
  }

  Future<void> _createNotificationChannel() async {
    final androidPlugin =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin != null) {
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        playSound: false,
        enableVibration: false,
        showBadge: true,
        enableLights: false,
      );

      await androidPlugin.createNotificationChannel(channel);
      print('✅ Notification channel created');
    }
  }

  Future<void> _requestPermissions() async {
    final androidPlugin =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      print('✅ Notification permission granted: $granted');
    }

    final iosPlugin =
        _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();

    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: false,
      );
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.actionId == 'stop_trip') {
      _stopTripFromNotification();
    } else if (response.actionId == 'add_cost') {
      _showAddCostDialog();
    } else {
      // Open trip screen (navigate to tab index 3)
      // Note: This will be handled by the MainNavigation widget
      print('Notification tapped - navigating to trip screen');
    }
  }

  void _stopTripFromNotification() {
    try {
      final controller = Get.find<MileageGetxController>();
      controller.stopTrip();
    } catch (e) {
      print('Error stopping trip from notification: $e');
    }
  }

  void _showAddCostDialog() {
    // This navigates to trip screen where user can add costs
    print('Add cost tapped - opening trip screen for cost entry');
  }

  Future<void> showTripNotification({
    required String tripId,
    required Duration duration,
    required double totalCost,
    required int costEntriesCount,
    DateTime? tripStartTime,
  }) async {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    final durationText =
        hours > 0
            ? '${hours}h ${minutes}m ${seconds}s'
            : minutes > 0
            ? '${minutes}m ${seconds}s'
            : '${seconds}s';

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      showWhen: true,
      when: (tripStartTime ?? DateTime.now()).millisecondsSinceEpoch,
      category: AndroidNotificationCategory.service,
      visibility: NotificationVisibility.public,
      usesChronometer: true,
      chronometerCountDown: false,
      color: const Color(0xFF00C853),
      colorized: false,
      subText: 'Active',
      ticker: 'Trip Started',
      showProgress: false,
      channelShowBadge: true,
      onlyAlertOnce: true,
      playSound: false,
      enableVibration: false,
      actions: const [
        AndroidNotificationAction(
          'add_cost',
          'Add Cost',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'stop_trip',
          'Stop Trip',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
      styleInformation: BigTextStyleInformation(
        'Duration: $durationText\nTotal Cost: ৳${totalCost.toStringAsFixed(2)}\nEntries: $costEntriesCount',
        contentTitle: 'Trip in Progress',
        summaryText: 'FuelBhai Trip Tracker',
        htmlFormatContent: false,
        htmlFormatContentTitle: false,
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    print(
      '📢 Showing trip notification - Duration: $durationText, Cost: ৳${totalCost.toStringAsFixed(2)}',
    );

    try {
      await _notifications.show(
        _notificationId,
        'Trip in Progress',
        'Duration: $durationText • Cost: ৳${totalCost.toStringAsFixed(2)}',
        details,
      );
      print('✅ Notification shown successfully');
    } catch (e) {
      print('❌ Error showing notification: $e');
    }
  }

  Future<void> cancelTripNotification() async {
    print('🔕 Cancelling trip notification');
    await _notifications.cancel(_notificationId);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
