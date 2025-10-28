// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      final result = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (result == true) {
        _initialized = true;
        debugPrint('✅ Notification service initialized successfully');

        // Request permissions for iOS
        await _requestPermissions();
      } else {
        debugPrint('❌ Notification service initialization failed');
      }
    } catch (e) {
      debugPrint('❌ Error initializing notifications: $e');
    }
  }

  Future<void> _requestPermissions() async {
    // Request permission for iOS
    await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // Request permission for Android 13+
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Handle notification tap here if needed
    // You can navigate to specific screens based on payload
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationPriority priority = NotificationPriority.high,
    NotificationImportance importance = NotificationImportance.high,
  }) async {
    if (!_initialized) {
      debugPrint(
        '⚠️ Notification service not initialized, initializing now...',
      );
      await initialize();
    }

    final androidDetails = AndroidNotificationDetails(
      'binova_channel',
      'Binova Notifications',
      channelDescription: 'Notifications for bin pickups and status updates',
      importance: importance.toPluginImportance(),
      priority: priority.toPluginPriority(),
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
      debugPrint('✅ Notification shown: $title');
    } catch (e) {
      debugPrint('❌ Error showing notification: $e');
    }
  }

  Future<void> showPickupReminderNotification({
    required String binType,
    required int hoursUntilPickup,
  }) async {
    final title = hoursUntilPickup <= 1
        ? '🔔 Pickup Soon!'
        : '⏰ Pickup Reminder';

    final body = hoursUntilPickup <= 1
        ? 'Your $binType pickup is in less than 1 hour!'
        : 'Your $binType pickup is scheduled in $hoursUntilPickup hours';

    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payload: 'pickup_reminder',
      priority: hoursUntilPickup <= 1
          ? NotificationPriority.max
          : NotificationPriority.high,
      importance: hoursUntilPickup <= 1
          ? NotificationImportance.max
          : NotificationImportance.high,
    );
  }

  Future<void> showBinStatusNotification({
    required String status,
    required String binType,
  }) async {
    String title;
    String body;

    switch (status) {
      case 'in-transit':
        title = '🚚 Collection Started';
        body = 'Your $binType bin is now in transit for collection!';
        break;
      case 'completed':
        title = '✅ Recycling Complete';
        body =
            'Your $binType has been successfully recycled. Thank you for helping the environment!';
        break;
      default:
        title = 'Bin Status Update';
        body = 'Your $binType bin status has been updated';
    }

    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payload: 'bin_status_$status',
      priority: NotificationPriority.high,
      importance: NotificationImportance.high,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}

// Enum for notification priority (Android)
enum NotificationPriority { min, low, defaultPriority, high, max }

// Enum for notification importance (Android)
enum NotificationImportance {
  unspecified,
  none,
  min,
  low,
  defaultImportance,
  high,
  max,
}

// Extension to convert custom enums to plugin enums
extension NotificationPriorityExtension on NotificationPriority {
  Priority toPluginPriority() {
    switch (this) {
      case NotificationPriority.min:
        return Priority.min;
      case NotificationPriority.low:
        return Priority.low;
      case NotificationPriority.defaultPriority:
        return Priority.defaultPriority;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.max:
        return Priority.max;
    }
  }
}

extension NotificationImportanceExtension on NotificationImportance {
  Importance toPluginImportance() {
    switch (this) {
      case NotificationImportance.unspecified:
        return Importance.unspecified;
      case NotificationImportance.none:
        return Importance.none;
      case NotificationImportance.min:
        return Importance.min;
      case NotificationImportance.low:
        return Importance.low;
      case NotificationImportance.defaultImportance:
        return Importance.defaultImportance;
      case NotificationImportance.high:
        return Importance.high;
      case NotificationImportance.max:
        return Importance.max;
    }
  }
}
