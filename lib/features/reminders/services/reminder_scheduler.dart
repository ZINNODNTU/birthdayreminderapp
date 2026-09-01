import 'dart:convert';
import 'dart:typed_data';

import '../../../core/logging/app_logger.dart';
import '../../../models/birthday.dart';
import '../../../services/notification_service.dart';
import '../../birthdays/domain/birthday_engine.dart';
import '../data/reminder_schedule_store.dart';
import '../domain/birthday_notification_formatter.dart';
import '../domain/notification_capability.dart';
import '../domain/reminder_failure.dart';
import '../domain/reminder_rule.dart';
import '../domain/reminder_schedule.dart';
import 'notification_id_factory.dart';
import 'notification_permission_service.dart';

const _reminderFormatter = BirthdayNotificationFormatter();

/// One concrete reminder occurrence derived from a birthday. Used by
/// [ReminderScheduler] to compute the next single annual reminder.
class ReminderOccurrence {
  const ReminderOccurrence({
    required this.year,
    required this.occurrenceDate,
    required this.scheduledAt,
  });

  final int year;
  final DateTime occurrenceDate;
  final DateTime scheduledAt;
}

/// Single entry-point for scheduling birthday reminders. V3 contract:
///
///   * Exactly ONE future pending reminder per birthday. After the
///     notification fires, the next maintenance reconciliation
///     schedules the following year's single reminder.
///   * Lunar / Feb-29 / solar recurrence all funnel through
///     [BirthdayEngine.occurrenceInYear] / [BirthdayEngine.nextOccurrence].
///   * Schema v3 scheduleKey shape: `birthday:<id>:next`.
///   * Unique notification id derived from the deterministic key via
///     FNV-1a 31-bit ([NotificationIdFactory]).
///   * Exact alarm when the OS allows, inexact fallback otherwise.
///   * Pending verification via [NotificationService.isNotificationPending]
///     so phantom store entries never survive.
class ReminderScheduler {
  ReminderScheduler({
    required BirthdayEngine engine,
    required NotificationIdFactory idFactory,
    required NotificationService notificationService,
    required NotificationPermissionService permissionService,
    required ReminderScheduleStore store,
  }) : _engine = engine,
       _idFactory = idFactory,
       _notificationService = notificationService,
       _permissionService = permissionService,
       _store = store,
       _builder = const ReminderScheduleBuilder();

  final BirthdayEngine _engine;
  final NotificationIdFactory _idFactory;
  final NotificationService _notificationService;
  final NotificationPermissionService _permissionService;
  final ReminderScheduleStore _store;
  final ReminderScheduleBuilder _builder;

  /// Build (but do NOT schedule) the single next future occurrence for
  /// [birthday]. Pure function — used by tests and the reconciler.
  static ReminderOccurrence? buildNextOccurrence(
    Birthday birthday,
    DateTime now, {
    required BirthdayEngine engine,
    required ReminderRule rule,
  }) {
    if (!rule.enabled) return null;
    // Walk forward year-by-year until we find a future scheduledAt.
    for (var y = now.year; y <= now.year + 8; y++) {
      final occDate = engine.occurrenceInYear(birthday, y);
      final scheduled = DateTime(
        occDate.year,
        occDate.month,
        occDate.day,
        rule.time.hour,
        rule.time.minute,
      ).subtract(Duration(days: rule.daysBefore));
      if (scheduled.isAfter(now)) {
        return ReminderOccurrence(
          year: y,
          occurrenceDate: DateTime(occDate.year, occDate.month, occDate.day),
          scheduledAt: scheduled,
        );
      }
    }
    return null;
  }

  /// Schedule the SINGLE next annual reminder for [birthday].
  ///
  /// Cancels every previously managed schedule for the birthday first
  /// so an edit never leaves an obsolete pending alarm.
  Future<ReminderScheduleResult> scheduleNextAnnualReminder(
    Birthday birthday,
  ) async {
    final rule = ReminderRule.fromBirthday(birthday);
    if (!rule.enabled) {
      await cancelAllFor(birthday.id);
      return ReminderScheduleResult.ok(scheduledCount: 0);
    }

    final caps = await _permissionService.query();
    if (caps.status == NotificationCapability.denied) {
      return ReminderScheduleResult.failure(
        kind: NotificationFailureKind.permissionDenied,
        message: 'Chưa cấp quyền thông báo.',
      );
    }
    final notificationsEnabled = caps.postNotifications;
    if (!notificationsEnabled) {
      return ReminderScheduleResult.failure(
        kind: NotificationFailureKind.notificationsDisabled,
        message: 'Thông báo đang tắt ở thiết bị.',
      );
    }
    final exact = caps.status == NotificationCapability.fullAccess;

    // Wipe any previously managed schedules for this birthday so an
    // edit never leaves orphan ids around.
    await _cancelManagedForBirthday(birthday.id);

    final now = DateTime.now();
    final occ = buildNextOccurrence(birthday, now, engine: _engine, rule: rule);
    if (occ == null) {
      return ReminderScheduleResult.failure(
        kind: NotificationFailureKind.invalidScheduleTime,
        message: 'Không tìm được lần nhắc kế tiếp trong 8 năm tới.',
      );
    }

    final avatar = _avatarBytesFor(birthday);
    final schedule = _builder.buildForOccurrence(
      birthday: birthday,
      rule: rule,
      year: occ.year,
      occurrenceDate: occ.occurrenceDate,
      scheduledAt: occ.scheduledAt,
      idFactory: _idFactory,
    );

    // First attempt: exact. If the plugin refuses (Samsung sometimes
    // silently drops inexact/exact flags), retry once with
    // inexactAllowWhileIdle and surface `exactUnavailableUsingFallback`.
    var usedExact = exact;
    var ok = await _notificationService.scheduleReminder(
      schedule,
      avatarBytes: avatar,
      exact: usedExact,
    );
    var fallbackKind = NotificationFailureKind.none;
    if (!ok && exact) {
      usedExact = false;
      ok = await _notificationService.scheduleReminder(
        schedule,
        avatarBytes: avatar,
        exact: usedExact,
      );
      if (ok) {
        fallbackKind = NotificationFailureKind.exactUnavailableUsingFallback;
      }
    }
    if (!ok) {
      AppLogger.warn(
        'ReminderScheduler',
        'failed to schedule year=${occ.year} id=${schedule.notificationId}',
      );
      return ReminderScheduleResult.failure(
        kind: NotificationFailureKind.scheduleFailed,
        message: 'Không thể đặt lịch.',
      );
    }

    // Verify the alarm landed on the OS before persisting. If the
    // plugin reports success but the OS does not have the id
    // registered, we DO NOT save the phantom store entry.
    final verified = await _notificationService.isNotificationPending(
      schedule.notificationId,
    );
    if (!verified) {
      AppLogger.warn(
        'ReminderScheduler',
        'pending verification failed year=${occ.year} id=${schedule.notificationId}',
      );
      // Roll back the orphan alarm so we don't leak OS-side state.
      await _notificationService.cancel(schedule.notificationId);
      return ReminderScheduleResult.failure(
        kind: NotificationFailureKind.pendingVerificationFailed,
        message: 'Hệ thống không xác nhận được lịch nhắc.',
      );
    }

    final newEntry = ManagedReminderEntry(
      scheduleKey: schedule.scheduleKey,
      notificationId: schedule.notificationId,
      fingerprint: schedule.scheduleKey,
      scheduledAt: schedule.scheduledAt,
      birthdayId: schedule.birthdayId,
      displayName: birthday.name.trim(),
      exact: usedExact,
    );
    final merged = _store.loadAll()..[schedule.scheduleKey] = newEntry;
    await _store.saveAll(merged);

    AppLogger.info(
      'ReminderScheduler',
      'scheduled birthdayId=${schedule.birthdayId} '
          'year=${occ.year} '
          'occurrence=${schedule.occurrenceDate} '
          'scheduledAt=${schedule.scheduledAt} '
          'exact=$usedExact '
          'notificationId=${schedule.notificationId}',
    );

    return ReminderScheduleResult(
      kind: fallbackKind,
      scheduledAt: schedule.scheduledAt,
      notificationId: schedule.notificationId,
      scheduledCount: 1,
      exact: exact,
    );
  }

  /// Backwards-compatible alias for the controller / detail screen /
  /// reconciler — every caller now hits the single-next path.
  Future<ReminderScheduleResult> scheduleNext(Birthday birthday) =>
      scheduleNextAnnualReminder(birthday);

  /// Backwards-compatible alias. Existing tests + product code still
  /// call `scheduleHorizon(birthday)`; V3 scheduleHorizon schedules
  /// exactly ONE future occurrence.
  Future<ReminderScheduleResult> scheduleHorizon(Birthday birthday) =>
      scheduleNextAnnualReminder(birthday);

  /// Cancel every reminder belonging to [birthdayId]. Used by delete
  /// and edit paths.
  Future<void> cancelAllFor(String birthdayId) async {
    await _cancelManagedForBirthday(birthdayId);
  }

  /// Schedule key generator. One ACTIVE entry per birthday:
  /// `birthday:<id>:next`. The deterministic id is derived from this
  /// key via FNV-1a so the same person always maps to the same
  /// notification id across rebuilds.
  static String scheduleKeyFor({
    required String birthdayId,
    String slot = 'next',
  }) => 'birthday:$birthdayId:$slot';

  /// Returns true when [key] is in the legacy shape
  /// `birthday:<id>:daysBefore:<N>:h:<HH>:m:<MM>` (v1) or the
  /// obsolete 3-year shape `birthday:<id>:year:<Y>:primary` (v2).
  static bool isLegacyKey(String key) {
    if (!key.startsWith('birthday:')) return false;
    if (key.contains(':daysBefore:')) return true;
    if (key.contains(':year:')) return true;
    return false;
  }

  /// Legacy key parser — accepts the new `birthday:<id>:next` shape,
  /// the v2 `birthday:<id>:year:<Y>:primary` shape, AND the v1
  /// `birthday:<id>:daysBefore:<N>:h:<HH>:m:<MM>` shape so existing
  /// store entries don't orphan during migration windows.
  static String? birthdayIdFromKey(String key) {
    const prefix = 'birthday:';
    if (!key.startsWith(prefix)) return null;
    final rest = key.substring(prefix.length);
    final sep = rest.indexOf(':');
    if (sep <= 0) return null;
    return rest.substring(0, sep);
  }

  Future<void> _cancelManagedForBirthday(String birthdayId) async {
    final entries = _store.loadAll();
    final keep = <String, ManagedReminderEntry>{};
    for (final entry in entries.values) {
      final ownerId = birthdayIdFromKey(entry.scheduleKey);
      if (ownerId == birthdayId) {
        await _notificationService.cancel(entry.notificationId);
      } else {
        keep[entry.scheduleKey] = entry;
      }
    }
    await _store.saveAll(keep);
  }

  Uint8List? _avatarBytesFor(Birthday birthday) {
    final raw = birthday.avatarBase64;
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      return base64Decode(raw);
    } catch (e, st) {
      AppLogger.warn(
        'ReminderScheduler',
        'avatarBase64 decode failed for ${birthday.id}: $e\n$st',
      );
      return null;
    }
  }
}

/// Pure function object — given a birthday + rule + target year,
/// returns the concrete [ReminderSchedule] for that occurrence.
class ReminderScheduleBuilder {
  const ReminderScheduleBuilder();

  /// Build a schedule for a specific target [year]. Used internally by
  /// the single-next scheduler; the engine recomputes the occurrence
  /// for that year (solar OR lunar OR Feb-29 fallback).
  ReminderSchedule buildForOccurrence({
    required Birthday birthday,
    required ReminderRule rule,
    required int year,
    required DateTime occurrenceDate,
    required DateTime scheduledAt,
    required NotificationIdFactory idFactory,
  }) {
    final payload = _reminderFormatter.buildForOccurrence(
      birthday: birthday,
      occurrence: occurrenceDate,
    );
    final key = ReminderScheduler.scheduleKeyFor(birthdayId: birthday.id);
    return ReminderSchedule(
      scheduleKey: key,
      notificationId: idFactory.idFor(key),
      birthdayId: birthday.id,
      occurrenceDate: occurrenceDate,
      occurrenceYear: year,
      scheduledAt: scheduledAt,
      title: payload.title,
      body: payload.body,
      payload: 'birthday:${birthday.id}',
    );
  }
}
