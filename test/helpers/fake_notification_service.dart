import 'package:birthdayreminderapp/features/reminders/domain/reminder_schedule.dart';
import 'package:birthdayreminderapp/services/notification_service.dart';

/// In-memory [NotificationService] used by widget / controller tests.
/// Never touches `flutter_local_notifications`.
class FakeNotificationService implements NotificationService {
  final List<ReminderSchedule> scheduled = [];
  final List<int> cancelled = [];
  final List<({String title, String body})> testShown = [];

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> scheduleReminder(
    ReminderSchedule schedule, {
    required bool exact,
  }) async {
    scheduled.add(schedule);
    return true;
  }

  @override
  Future<bool> cancel(int notificationId) async {
    cancelled.add(notificationId);
    return true;
  }

  @override
  Future<bool> showTestNotification({
    required String title,
    required String body,
  }) async {
    testShown.add((title: title, body: body));
    return true;
  }
}
