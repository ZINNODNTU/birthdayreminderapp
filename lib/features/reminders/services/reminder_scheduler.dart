import '../../../models/birthday.dart';
import '../../birthdays/domain/birthday_engine.dart';
import '../data/reminder_schedule_store.dart';
import '../domain/notification_capability.dart';
import '../domain/reminder_failure.dart';
import '../domain/reminder_rule.dart';
import '../domain/reminder_schedule.dart';
import 'notification_id_factory.dart';
import 'notification_permission_service.dart';
import '../../../services/notification_service.dart';

/// Single entry-point for "schedule the next reminder for this
/// birthday". Centralises:
///
///  * next-occurrence lookup (via [BirthdayEngine])
///  * subtract-days / apply-time math
///  * deterministic id derivation
///  * exact vs inexact scheduling based on capability
///  * registry updates (via the store)
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

  /// Schedule the next reminder for [birthday] using its on-record
  /// fields (remindBeforeDays, remindTime, isRecurringNotificationEnabled).
  /// If reminders are disabled, any existing reminder for the same
  /// schedule key is cancelled instead.
  Future<ReminderScheduleResult> scheduleNext(Birthday birthday) async {
    final rule = ReminderRule.fromBirthday(birthday);
    final key = scheduleKeyFor(birthday.id, rule);
    if (!rule.enabled) {
      await _cancelForKey(key);
      return ReminderScheduleResult.ok(scheduledCount: 0);
    }

    final caps = await _permissionService.query();
    if (caps.status == NotificationCapability.denied) {
      return ReminderScheduleResult.failure(
        kind: NotificationFailureKind.permissionDenied,
      );
    }
    final exact = caps.status == NotificationCapability.fullAccess;

    final schedule = _builder.build(
      birthday: birthday,
      rule: rule,
      engine: _engine,
      idFactory: _idFactory,
    );
    if (schedule == null) {
      return ReminderScheduleResult.ok(scheduledCount: 0);
    }

    final ok = await _notificationService.scheduleReminder(
      schedule,
      exact: exact,
    );
    if (!ok) {
      return ReminderScheduleResult.failure(
        kind: NotificationFailureKind.scheduleFailed,
      );
    }
    await _put(schedule);
    return ReminderScheduleResult.ok();
  }

  /// Cancel every reminder belonging to [birthdayId]. Used by delete.
  Future<void> cancelAllFor(String birthdayId) async {
    final entries = _store.loadAll();
    final keep = <String, ManagedReminderEntry>{};
    for (final entry in entries.values) {
      if (entry.scheduleKey.startsWith('birthday:$birthdayId:')) {
        await _notificationService.cancel(entry.notificationId);
      } else {
        keep[entry.scheduleKey] = entry;
      }
    }
    await _store.saveAll(keep);
  }

  /// Public helper — used by tests and the reconciler.
  static String scheduleKeyFor(String birthdayId, ReminderRule rule) =>
      'birthday:$birthdayId:daysBefore:${rule.daysBefore}:'
      'h:${rule.time.hour}:m:${rule.time.minute}';

  /// Extract the birthday id segment from a schedule key, or `null`
  /// if the key doesn't follow our format.
  static String? birthdayIdFromKey(String key) {
    const prefix = 'birthday:';
    if (!key.startsWith(prefix)) return null;
    final rest = key.substring(prefix.length);
    final sep = rest.indexOf(':');
    if (sep <= 0) return null;
    return rest.substring(0, sep);
  }

  Future<void> _cancelForKey(String key) async {
    final entries = _store.loadAll();
    final entry = entries[key];
    if (entry != null) {
      await _notificationService.cancel(entry.notificationId);
    }
    final filtered = {...entries}..remove(key);
    await _store.saveAll(filtered);
  }

  Future<void> _put(ReminderSchedule schedule) async {
    final entries = _store.loadAll();
    entries[schedule.scheduleKey] = ManagedReminderEntry(
      scheduleKey: schedule.scheduleKey,
      notificationId: schedule.notificationId,
      fingerprint: schedule.scheduleKey,
    );
    await _store.saveAll(entries);
  }
}

/// Pure function object — given a birthday + rule, returns the
/// concrete [ReminderSchedule] or `null` if there's nothing valid to
/// schedule.
class ReminderScheduleBuilder {
  const ReminderScheduleBuilder();

  ReminderSchedule? build({
    required Birthday birthday,
    required ReminderRule rule,
    required BirthdayEngine engine,
    required NotificationIdFactory idFactory,
    DateTime? now,
  }) {
    final today = _truncate(now ?? DateTime.now());

    var occurrence = engine.nextOccurrence(birthday, from: today);
    var scheduledAt = DateTime(
      occurrence.year,
      occurrence.month,
      occurrence.day,
      rule.time.hour,
      rule.time.minute,
    ).subtract(Duration(days: rule.daysBefore));

    if (!scheduledAt.isAfter(today)) {
      final nextOcc = engine.nextOccurrence(
        birthday,
        from: today.add(const Duration(days: 1)),
      );
      occurrence = nextOcc;
      scheduledAt = DateTime(
        occurrence.year,
        occurrence.month,
        occurrence.day,
        rule.time.hour,
        rule.time.minute,
      ).subtract(Duration(days: rule.daysBefore));
    }

    final scheduleKey = ReminderScheduler.scheduleKeyFor(birthday.id, rule);

    return ReminderSchedule(
      scheduleKey: scheduleKey,
      notificationId: idFactory.idFor(scheduleKey),
      birthdayId: birthday.id,
      occurrenceDate: DateTime(
        occurrence.year,
        occurrence.month,
        occurrence.day,
      ),
      scheduledAt: scheduledAt,
      title: 'Sắp đến sinh nhật 🎉',
      body:
          '${birthday.name} sẽ có sinh nhật vào ngày '
          '${occurrence.day}/${occurrence.month}',
      payload: 'birthday:${birthday.id}',
    );
  }

  static DateTime _truncate(DateTime d) => DateTime(d.year, d.month, d.day);
}
