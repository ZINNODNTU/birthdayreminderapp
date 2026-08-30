import '../../../models/birthday.dart';
import '../../birthdays/data/birthday_repository.dart';
import '../data/reminder_schedule_store.dart';
import '../domain/notification_capability.dart';
import '../domain/reminder_failure.dart';
import 'notification_permission_service.dart';
import 'reminder_scheduler.dart';

/// Reconciles desired reminders (from the [BirthdayRepository]) with
/// the OS-known managed set. Called on app start, after package
/// replacement, after lifecycle pause/resume, and after the user
/// signs in / out.
///
/// V3 contract: every live birthday has EXACTLY ONE future pending
/// notification. After the OS fires it, the next maintenance cycle
/// detects the missing future entry and re-schedules the following
/// year's single reminder.
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

  /// Maintenance tick: ensure every live birthday has exactly ONE
  /// future pending notification. Cancels managed entries for
  /// deleted birthdays; reschedules only when the desired single
  /// future entry is missing OR has already fired.
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
    final desiredIds = <String>{for (final b in birthdays) b.id};

    // Cancel managed entries that no longer map to a live birthday.
    int cancelled = 0;
    final managed = _store.loadAll();
    final keep = <String, ManagedReminderEntry>{};
    for (final entry in managed.values) {
      final ownerId = ReminderScheduler.birthdayIdFromKey(entry.scheduleKey);
      if (ownerId == null) {
        keep[entry.scheduleKey] = entry;
        continue;
      }
      if (!desiredIds.contains(ownerId)) {
        await _scheduler.cancelAllFor(ownerId);
        cancelled++;
        continue;
      }
      keep[entry.scheduleKey] = entry;
    }
    await _store.saveAll(keep);

    // For every live birthday ensure exactly ONE future pending
    // notification exists if repeatAnnually is true. If repeatAnnually is false,
    // only keep the one-time reminder and do not reschedule after it fires.
    int scheduled = 0;
    final now = DateTime.now();
    for (final b in birthdays) {
      final v3Key = ReminderScheduler.scheduleKeyFor(birthdayId: b.id);
      final existing = keep[v3Key];
      if (existing != null &&
          existing.scheduledAt != null &&
          existing.scheduledAt!.isAfter(now)) {
        // Healthy: there's still a future pending — leave it alone.
        scheduled++;
        continue;
      }
      // Otherwise drop the orphan.
      if (existing != null) {
        // The orphan entry is owned by `b.id`; scheduler.cancelAllFor
        // removes the OS notification and the matching store entries.
        await _scheduler.cancelAllFor(b.id);
        keep.remove(v3Key);
        await _store.saveAll(keep);
      }
      // Only reschedule if repeatAnnually is true.
      if (b.repeatAnnually) {
        final result = await _scheduler.scheduleNextAnnualReminder(b);
        if (result.isOk) {
          scheduled++;
        }
      }
    }

    return ReminderReconcileResult.ok(
      cancelled: cancelled,
      scheduled: scheduled,
    );
  }
}

class ReminderReconcileResult {
  const ReminderReconcileResult({
    required this.kind,
    required this.cancelled,
    required this.scheduled,
    this.message,
  });

  factory ReminderReconcileResult.ok({
    required int cancelled,
    required int scheduled,
  }) => ReminderReconcileResult(
    kind: NotificationFailureKind.none,
    cancelled: cancelled,
    scheduled: scheduled,
  );

  final NotificationFailureKind kind;
  final int cancelled;
  final int scheduled;
  final String? message;

  bool get isOk => kind == NotificationFailureKind.none;
}
