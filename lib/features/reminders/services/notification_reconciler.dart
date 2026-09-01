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
  /// future pending notification. [onProgress] emits after every birthday.
  Future<ReminderReconcileResult> reconcile({
    void Function(ReminderReconcileProgress progress)? onProgress,
  }) async {
    final caps = await _permissionService.query();
    if (caps.status == NotificationCapability.denied) {
      return ReminderReconcileResult(
        kind: NotificationFailureKind.permissionDenied,
        cancelled: 0,
        scheduled: 0,
        failed: 1,
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
    int failed = 0;
    String? lastError;
    int processed = 0;
    final total = birthdays.length;
    final now = DateTime.now();
    for (final b in birthdays) {
      onProgress?.call(
        ReminderReconcileProgress(
          processed: processed,
          total: total,
          displayName: b.name.trim().isEmpty ? 'Không có tên' : b.name.trim(),
        ),
      );
      final v3Key = ReminderScheduler.scheduleKeyFor(birthdayId: b.id);
      final existing = keep[v3Key];

      if (!b.isRecurringNotificationEnabled) {
        if (existing != null) {
          await _scheduler.cancelAllFor(b.id);
          keep.remove(v3Key);
          cancelled++;
        }
        processed++;
        onProgress?.call(
          ReminderReconcileProgress(
            processed: processed,
            total: total,
            displayName: b.name.trim().isEmpty ? 'Không có tên' : b.name.trim(),
          ),
        );
        continue;
      }

      if (existing != null &&
          existing.scheduledAt != null &&
          existing.scheduledAt!.isAfter(now)) {
        // Healthy: there's still a future pending — leave it alone.
        scheduled++;
        processed++;
        onProgress?.call(
          ReminderReconcileProgress(
            processed: processed,
            total: total,
            displayName: b.name.trim().isEmpty ? 'Không có tên' : b.name.trim(),
          ),
        );
        continue;
      }

      final hadExpiredEntry = existing != null;
      if (hadExpiredEntry) {
        await _scheduler.cancelAllFor(b.id);
        keep.remove(v3Key);
        await _store.saveAll(keep);
      }

      // Every enabled birthday gets its initial reminder. Once a one-shot
      // entry has fired (represented by its expired store entry), only an
      // annually repeating birthday may advance to another occurrence.
      if (!hadExpiredEntry || b.repeatAnnually) {
        final result = await _scheduler.scheduleNextAnnualReminder(b);
        if (result.isOk) {
          scheduled++;
        } else {
          failed++;
          lastError = result.message ?? result.kind.name;
        }
      }
      processed++;
      onProgress?.call(
        ReminderReconcileProgress(
          processed: processed,
          total: total,
          displayName: b.name.trim().isEmpty ? 'Không có tên' : b.name.trim(),
        ),
      );
    }

    return ReminderReconcileResult.ok(
      cancelled: cancelled,
      scheduled: scheduled,
      failed: failed,
      message: lastError,
    );
  }
}

class ReminderReconcileResult {
  const ReminderReconcileResult({
    required this.kind,
    required this.cancelled,
    required this.scheduled,
    this.failed = 0,
    this.message,
  });

  factory ReminderReconcileResult.ok({
    required int cancelled,
    required int scheduled,
    int failed = 0,
    String? message,
  }) => ReminderReconcileResult(
    kind: failed == 0
        ? NotificationFailureKind.none
        : NotificationFailureKind.scheduleFailed,
    cancelled: cancelled,
    scheduled: scheduled,
    failed: failed,
    message: message,
  );

  final NotificationFailureKind kind;
  final int cancelled;
  final int scheduled;
  final int failed;
  final String? message;

  bool get isOk => kind == NotificationFailureKind.none;
}

class ReminderReconcileProgress {
  const ReminderReconcileProgress({
    required this.processed,
    required this.total,
    required this.displayName,
  });

  final int processed;
  final int total;
  final String displayName;
}
