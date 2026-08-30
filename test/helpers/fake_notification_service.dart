import 'dart:typed_data';

import 'package:birthdayreminderapp/features/reminders/domain/reminder_schedule.dart';
import 'package:birthdayreminderapp/services/notification_service.dart';

/// In-memory [NotificationService] used by widget / controller tests.
/// Never touches `flutter_local_notifications`.
class FakeNotificationService implements NotificationService {
  FakeNotificationService({NotificationTestResult? testResultOverride})
    : _override = testResultOverride;

  final List<ReminderSchedule> scheduled = [];
  final List<int> cancelled = [];
  final List<({String title, String body})> testShown = [];
  final NotificationTestResult? _override;

  int initializeCalls = 0;

  @override
  Future<void> initialize() async {
    initializeCalls++;
  }

  @override
  Future<bool> scheduleReminder(
    ReminderSchedule schedule, {
    Uint8List? avatarBytes,
    required bool exact,
  }) async {
    scheduled.add(schedule);
    return true;
  }

  @override
  Future<bool> isNotificationPending(int id) async {
    return cancelled.contains(id) == false;
  }

  @override
  Future<ScheduledTestResult> scheduleOneMinuteDiagnostic({
    required String title,
    required String body,
  }) async {
    return ScheduledTestResult(
      scheduled: true,
      scheduledAt: DateTime.now().add(const Duration(minutes: 1)),
      permissionGranted: true,
      notificationsEnabled: true,
      exactAvailable: true,
      pendingConfirmed: true,
    );
  }

  @override
  Future<bool> cancel(int notificationId) async {
    cancelled.add(notificationId);
    return true;
  }

  @override
  Future<NotificationTestResult> showTestNotification({
    required String title,
    required String body,
  }) async {
    testShown.add((title: title, body: body));
    return _override ??
        const NotificationTestResult(
          initialized: true,
          permissionGranted: true,
          notificationsEnabled: true,
          channelCreated: true,
          showCalled: true,
        );
  }

  ScheduledTestResult? scheduledTestResultOverride;
  final List<({String title, String body, Duration delay})> testScheduled = [];

  @override
  Future<ScheduledTestResult> scheduleTestNotification({
    required String title,
    required String body,
    Duration delay = const Duration(seconds: 10),
  }) async {
    testScheduled.add((title: title, body: body, delay: delay));
    return scheduledTestResultOverride ??
        ScheduledTestResult(
          scheduled: true,
          scheduledAt: DateTime.now().add(delay),
          permissionGranted: true,
          notificationsEnabled: true,
          exactAvailable: true,
          pendingConfirmed: true,
        );
  }

  @override
  Future<bool> openAppNotificationSettings() async => true;

  @override
  Future<bool?> canScheduleExactNotifications() async => true;

  @override
  Future<void> requestExactAlarmsPermission() async {}

  @override
  Future<NotificationRuntimeSnapshot> runtimeSnapshot() async {
    return NotificationRuntimeSnapshot(
      permissionGranted: true,
      notificationsEnabled: true,
      exactAvailable: true,
      exactCanRequest: false,
      tzLocalName: 'Asia/Ho_Chi_Minh',
      deviceNow: DateTime.now(),
      deviceUtc: DateTime.now().toUtc(),
      utcOffsetMinutes: 420,
    );
  }

  @override
  Future<bool> openExactAlarmSettings() async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
