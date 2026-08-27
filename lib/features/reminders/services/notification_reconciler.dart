import '../../../models/birthday.dart';
import '../../birthdays/data/birthday_repository.dart';
import '../data/reminder_schedule_store.dart';
import '../domain/notification_capability.dart';
import '../domain/reminder_failure.dart';
import 'notification_permission_service.dart';
import 'reminder_scheduler.dart';

/// Reconciles desired reminders (from the [BirthdayRepository]) with
/// the OS-known managed set. Called on app start, after package
/// replacement, and after the user signs in / out.
class NotificationReconciler {
  NotificationReconciler({
    required BirthdayRepository repository,
    required ReminderScheduler scheduler,
    required NotificationPermissionService permissionService,
    required ReminderScheduleStore store,
  }) : _repository = repository,
       _scheduler = scheduler,
       _permissionService = permissionService,
       _store = store;

  final BirthdayRepository _repository;
  final ReminderScheduler _scheduler;
  final NotificationPermissionService _permissionService;
  final ReminderScheduleStore _store;

  Future<ReminderReconcileResult> reconcile() async {
    final caps = await _permissionService.query();
    if (caps.status == NotificationCapability.denied) {
      return ReminderReconcileResult(
        kind: NotificationFailureKind.permissionDenied,
        cancelled: 0,
        scheduled: 0,
        message: 'Notifications are disabled by the OS.',
      );
    }

    final List<Birthday> birthdays = await _repository.getBirthdays();
    final desired = <String>{for (final b in birthdays) b.id};

    // Cancel anything managed that no longer maps to a birthday.
    int cancelled = 0;
    final managed = _store.loadAll();
    final keep = <String, ManagedReminderEntry>{};
    for (final entry in managed.values) {
      final ownerId = ReminderScheduler.birthdayIdFromKey(entry.scheduleKey);
      if (ownerId == null) continue;
      if (!desired.contains(ownerId)) {
        await _scheduler.cancelAllFor(ownerId);
        cancelled++;
        continue;
      }
      keep[entry.scheduleKey] = entry;
    }
    await _store.saveAll(keep);

    int scheduled = 0;
    for (final b in birthdays) {
      final result = await _scheduler.scheduleNext(b);
      if (result.isOk && result.scheduledCount > 0) scheduled++;
    }

    return ReminderReconcileResult.ok(
      cancelled: cancelled,
      scheduled: scheduled,
    );
  }
}
