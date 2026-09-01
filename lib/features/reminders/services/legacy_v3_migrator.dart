import '../../../core/logging/app_logger.dart';
import '../../../services/notification_service.dart';
import '../data/reminder_schedule_store.dart';
import 'reminder_scheduler.dart';

/// One-shot migration from the v2 schedule-key shape
/// (`birthday:<id>:year:<Y>:primary`) to the v3 single-next shape
/// (`birthday:<id>:next`).
///
/// **Safety contract.**
///   * Cancels the obsolete v2 ids for a birthday while keeping at
///     most ONE future schedule (the nearest future occurrence).
///   * NEVER calls [NotificationService.cancelAll]; unrelated
///     notifications (e.g. diagnostic `0x6E5F00D`) are preserved.
///   * Idempotent: a second call after the schema version is already
///     at v3 is a noop.
///   * After migration the version is bumped and the store is the
///     single source of truth that the reconciler rebuilds from.
class LegacyToV3Migrator {
  LegacyToV3Migrator({
    required ReminderScheduleStore store,
    required NotificationService notificationService,
  }) : _store = store,
       _notificationService = notificationService;

  final ReminderScheduleStore _store;
  final NotificationService _notificationService;

  /// Run the v2→v3 migration if the store is still on schema v2 (or
  /// v1, although the v1→v2 migrator should have already fired first).
  /// Returns the number of legacy notification ids that were cancelled.
  Future<int> runIfNeeded() async {
    if (_store.schemaVersion >= ReminderScheduleStore.currentSchemaVersion) {
      return 0;
    }

    final entries = _store.loadAll();
    var cancelled = 0;

    // Group by birthdayId. For each birthday:
    //   1. Find the OBSERVANCE whose scheduledAt is the NEAREST FUTURE.
    //      If none are future, keep the most-recent past one so the
    //      next reconciler run will rebuild from scratch.
    //   2. Cancel every other managed id for that birthday.
    //   3. Re-emit the kept id under the v3 scheduleKey shape.
    final byBirthday = <String, List<ManagedReminderEntry>>{};
    for (final entry in entries.values) {
      if (ReminderScheduler.isLegacyKey(entry.scheduleKey)) {
        final ownerId = ReminderScheduler.birthdayIdFromKey(entry.scheduleKey);
        if (ownerId == null) continue;
        byBirthday.putIfAbsent(ownerId, () => []).add(entry);
      }
    }

    final kept = <String, ManagedReminderEntry>{};
    final now = DateTime.now();
    for (final list in byBirthday.values) {
      // Prefer the earliest future occurrence.
      final future =
          list
              .where(
                (e) => e.scheduledAt != null && e.scheduledAt!.isAfter(now),
              )
              .toList()
            ..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));
      final ManagedReminderEntry survivor;
      if (future.isNotEmpty) {
        survivor = future.first;
      } else {
        final sorted = [...list]
          ..sort(
            (a, b) => (b.scheduledAt ?? DateTime(1970)).compareTo(
              a.scheduledAt ?? DateTime(1970),
            ),
          );
        survivor = sorted.first;
      }
      for (final e in list) {
        if (identical(e, survivor)) continue;
        try {
          await _notificationService.cancel(e.notificationId);
          cancelled++;
        } catch (_) {
          // Best effort — we still drop the store entry below.
        }
      }
      // Re-key the survivor under the v3 shape so subsequent reads /
      // maintenance use the unified key.
      final v3Key = ReminderScheduler.scheduleKeyFor(
        birthdayId: survivor.birthdayId,
      );
      kept[v3Key] = ManagedReminderEntry(
        scheduleKey: v3Key,
        notificationId: survivor.notificationId,
        fingerprint: survivor.fingerprint,
        scheduledAt: survivor.scheduledAt,
        birthdayId: survivor.birthdayId,
        exact: survivor.exact,
      );
    }

    // Drop any non-grouped legacy keys (orphans).
    final orphanIds = entries.values
        .where(
          (e) =>
              !byBirthday.containsKey(e.birthdayId) &&
              ReminderScheduler.isLegacyKey(e.scheduleKey),
        )
        .toList();
    for (final e in orphanIds) {
      try {
        await _notificationService.cancel(e.notificationId);
        cancelled++;
      } catch (_) {
        // ignored
      }
    }

    await _store.saveAll(kept);
    await _store.setSchemaVersion(ReminderScheduleStore.currentSchemaVersion);
    AppLogger.info(
      'ReminderMigration',
      'v2->v3 cancelled=$cancelled kept=${kept.length}',
    );
    return cancelled;
  }
}
