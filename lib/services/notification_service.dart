import 'dart:developer' as devtools show log;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/birthday.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  late FlutterLocalNotificationsPlugin _notificationsPlugin;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _notificationsPlugin = FlutterLocalNotificationsPlugin();
    tz.initializeTimeZones();

    final String timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    final status = await Permission.notification.status;
    if (!status.isGranted) {
      final result = await Permission.notification.request();
      if (!result.isGranted) {
        devtools.log("❌ Notification permission NOT granted");
        return;
      }
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        devtools.log('🟣 Notification clicked: ${response.payload}');
      },
    );

    _isInitialized = true;
    devtools.log('✅ Notification service initialized');
  }

  Future<void> scheduleBirthdayNotification(Birthday birthday) async {
    await initialize();

    final DateTime now = DateTime.now();

    // Chuyển đổi ngày sinh nhật thành ngày dương nếu là âm lịch
    final DateTime birthdayDate = birthday.calendarType == CalendarType.solar
        ? birthday.solarBirthday
        : birthday.lunarBirthday.toSolarDateTime();

    // Xác định năm sinh nhật tiếp theo (năm nay hoặc năm sau)
    DateTime nextBirthday = DateTime(now.year, birthdayDate.month, birthdayDate.day);
    if (nextBirthday.isBefore(now)) {
      nextBirthday = DateTime(now.year + 1, birthdayDate.month, birthdayDate.day);
    }

    // Ngày cần nhắc = ngày sinh - số ngày trước
    final DateTime remindDate = nextBirthday.subtract(Duration(days: birthday.remindBeforeDays));

    // Tạo TZDateTime với múi giờ cục bộ
    tz.TZDateTime scheduledTime = tz.TZDateTime.local(
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
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime, // 🔁 Lặp lại hằng năm
    );

    devtools.log('✅ Scheduled yearly notification for ${birthday.name} at $scheduledTime');
  }

  Future<void> cancelNotification(String id) async {
    await initialize();
    await _notificationsPlugin.cancel(id.hashCode);
    devtools.log('❌ Canceled notification for $id');
  }

  Future<void> testNotification(Birthday birthday) async {
    await initialize();

    final int days = daysUntilNextBirthday(
      birthday.calendarType == CalendarType.solar
          ? birthday.solarBirthday
          : birthday.lunarBirthday.toSolarDateTime(),
    );

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

    devtools.log('✅ Immediate test notification shown for ${birthday.name}');
  }

  int daysUntilNextBirthday(DateTime birthday) {
    final now = DateTime.now();
    DateTime nextBirthday = DateTime(now.year, birthday.month, birthday.day);
    if (nextBirthday.isBefore(now)) {
      nextBirthday = DateTime(now.year + 1, birthday.month, birthday.day);
    }
    return nextBirthday.difference(now).inDays;
  }
}
