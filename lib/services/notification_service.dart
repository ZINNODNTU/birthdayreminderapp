import 'dart:async';
import 'dart:developer' as devtools;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../features/birthdays/domain/birthday_engine.dart';
import '../models/birthday.dart';

/// Wraps `flutter_local_notifications`. Notification IDs intentionally
/// still use `birthday.id.hashCode` — that's a Phase 4 concern.
class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

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

    await _notificationsPlugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (response) {
        devtools.log('🟣 Notification clicked: ${response.payload}');
      },
    );

    _isInitialized = true;
    devtools.log('✅ Notification service initialized');
  }

  /// Schedule the next occurrence of [birthday] using [engine] for the
  /// correct solar date in the next applicable year. The reminder offset
  /// and time-of-day still come from the [Birthday] record itself.
  Future<void> scheduleBirthdayNotification(
    Birthday birthday,
    BirthdayEngine engine,
  ) async {
    await initialize();

    final DateTime now = DateTime.now();
    final DateTime birthdayDate = engine.occurrenceInYear(birthday, now.year);

    DateTime nextBirthday = DateTime(
      birthdayDate.year,
      birthdayDate.month,
      birthdayDate.day,
    );
    if (nextBirthday.isBefore(now)) {
      final nextYearDate = engine.occurrenceInYear(birthday, now.year + 1);
      nextBirthday = DateTime(
        nextYearDate.year,
        nextYearDate.month,
        nextYearDate.day,
      );
    }

    final DateTime remindDate = nextBirthday.subtract(
      Duration(days: birthday.remindBeforeDays),
    );

    final tz.TZDateTime scheduledTime = tz.TZDateTime.local(
      remindDate.year,
      remindDate.month,
      remindDate.day,
      birthday.remindTime.hour,
      birthday.remindTime.minute,
    );

    devtools.log('📅 Scheduled Time: $scheduledTime');

    await _notificationsPlugin.zonedSchedule(
      birthday.id.hashCode,
      'Sắp đến sinh nhật 🎉',
      '${birthday.name} sẽ có sinh nhật vào ngày ${birthdayDate.day}/${birthdayDate.month}',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'birthday_channel',
          'Birthday Reminders',
          channelDescription: 'Thông báo sinh nhật',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: birthday.id,
      matchDateTimeComponents:
          DateTimeComponents.dayOfMonthAndTime, // 🔁 Lặp lại hằng năm
    );

    devtools.log(
      '✅ Scheduled yearly notification for ${birthday.name} at $scheduledTime',
    );
  }

  Future<void> cancelNotification(String id) async {
    await initialize();
    await _notificationsPlugin.cancel(id.hashCode);
    devtools.log('❌ Canceled notification for $id');
  }

  Future<void> testNotification(
    Birthday birthday,
    BirthdayEngine engine,
  ) async {
    await initialize();

    final int days = engine.daysUntilNextBirthday(birthday);

    await _notificationsPlugin.show(
      birthday.id.hashCode,
      'Thông báo thử',
      'Sinh nhật của ${birthday.name} còn $days ngày nữa',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'birthday_channel',
          'Birthday Reminders',
          channelDescription: 'Thông báo sinh nhật',
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
  }
}

// Re-export the foundation type to silence "unused_import" when this file
// is consumed without the rest of the app.
// ignore: unused_element
typedef _Debug = ChangeNotifier;
