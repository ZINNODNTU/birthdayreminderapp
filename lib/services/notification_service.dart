import 'dart:async';
import 'dart:developer' as devtools;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../features/reminders/domain/notification_capability.dart';
import '../features/reminders/domain/reminder_schedule.dart';

/// Thin adapter around `flutter_local_notifications`. Phase 4 removes
/// `birthday.id.hashCode` and accepts the [ReminderSchedule] the
/// scheduler computed (with a deterministic id already baked in).
class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const String androidChannelId = 'birthday_reminders';
  static const String androidChannelName = 'Birthday Reminders';
  static const String androidChannelDescription =
      'Nhắc nhở sinh nhật cho bạn bè và người thân.';

  /// Test-only notification id, isolated from the production id
  /// space so the test button cannot accidentally overwrite a real
  /// reminder.
  static const int testNotificationId = 0x6E5F00D;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (response) {
        devtools.log('🟣 Notification clicked: ${response.payload}');
      },
    );

    _isInitialized = true;
    devtools.log('✅ Notification service initialized');
  }

  /// Schedule a single [schedule] for the upcoming occurrence. The
  /// caller has already chosen `exact` vs `inexact` based on the
  /// current [NotificationCapability]. Returns false on failure;
  /// never throws for permission issues.
  Future<bool> scheduleReminder(
    ReminderSchedule schedule, {
    required bool exact,
  }) async {
    await initialize();
    try {
      final tzTime = tz.TZDateTime.from(schedule.scheduledAt, tz.local);
      await _plugin.zonedSchedule(
        schedule.notificationId,
        schedule.title,
        schedule.body,
        tzTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            androidChannelId,
            androidChannelName,
            channelDescription: androidChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode:
            exact
                ? AndroidScheduleMode.exactAllowWhileIdle
                : AndroidScheduleMode.inexactAllowWhileIdle,
        payload: schedule.payload,
      );
      return true;
    } catch (e) {
      devtools.log('❌ scheduleReminder failed: $e');
      return false;
    }
  }

  Future<bool> cancel(int notificationId) async {
    await initialize();
    try {
      await _plugin.cancel(notificationId);
      return true;
    } catch (e) {
      devtools.log('❌ cancel failed: $e');
      return false;
    }
  }

  /// Fire an immediate test notification using [testNotificationId].
  /// Does NOT interact with the production reminder id space.
  Future<bool> showTestNotification({
    required String title,
    required String body,
  }) async {
    await initialize();
    try {
      await _plugin.show(
        testNotificationId,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            androidChannelId,
            androidChannelName,
            channelDescription: androidChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      return true;
    } catch (e) {
      devtools.log('❌ test notification failed: $e');
      return false;
    }
  }
}
