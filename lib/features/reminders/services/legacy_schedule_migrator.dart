import '../../../services/notification_service.dart';
import '../data/reminder_schedule_store.dart';
import 'reminder_scheduler.dart';

/// One-shot migration from the legacy v1 schedule-key shape
/// (`birthday:<id>:daysBefore:<N>:h:<HH>:m:<MM>`) to a clean store.
///
/// **Safety contract.**
///   * Only cancels notification ids that are managed by this app AND
///     whose scheduleKey is in the v1 ("daysBefore") shape.
///   * Never calls [NotificationService.cancelAll]; unrelated
///     notifications (e.g. the diagnostic `0x6E5F00D`) are preserved.
///   * Idempotent: schemaVersion >= 2 is a noop. v2 → v3 migration
///     lives in [LegacyToV3Migrator] so each step is small and
///     inspectable.
class LegacyScheduleMigrator {
  LegacyScheduleMigrator({
    required ReminderScheduleStore store,
    required NotificationService notificationService,
  }) : _store = store,
       _notificationService = notificationService;

  final ReminderScheduleStore _store;
  final NotificationService _notificationService;

  /// Run the migration if the store still has v1 entries. Returns
  /// the number of legacy notification ids that were cancelled.
  Future<int> runIfNeeded() async {
    if (_store.schemaVersion >= 2) return 0;
    final entries = _store.loadAll();
    var cancelled = 0;
    for (final entry in entries.values) {
      if (!ReminderScheduler.isLegacyKey(entry.scheduleKey)) continue;
      try {
        await _notificationService.cancel(entry.notificationId);
        cancelled++;
      } catch (_) {
        // Best effort — we still drop the store entry below.
      }
    }
    await _store.clear();
    await _store.setSchemaVersion(2);
    return cancelled;
  }
}
