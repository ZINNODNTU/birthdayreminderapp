import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:birthdayreminderapp/features/birthdays/domain/lunar_calendar_service.dart';
import 'package:birthdayreminderapp/features/reminders/data/reminder_schedule_store.dart';
import 'package:birthdayreminderapp/features/reminders/domain/notification_capability.dart';
import 'package:birthdayreminderapp/features/reminders/services/legacy_v3_migrator.dart';
import 'package:birthdayreminderapp/features/reminders/services/notification_id_factory.dart';
import 'package:birthdayreminderapp/features/reminders/services/notification_permission_service.dart';
import 'package:birthdayreminderapp/features/reminders/services/reminder_scheduler.dart';
import 'package:birthdayreminderapp/models/birthday.dart';
import 'package:birthdayreminderapp/services/notification_service.dart';
import 'package:birthdayreminderapp/features/birthdays/domain/birthday_engine.dart';
import 'package:birthdayreminderapp/features/birthdays/domain/default_birthday_engine.dart';

import 'package:birthdayreminderapp/features/reminders/domain/reminder_schedule.dart';
import 'package:birthdayreminderapp/features/reminders/domain/reminder_rule.dart';

class _MockNotificationService extends Mock implements NotificationService {}

class _MockPermissionService extends Mock
    implements NotificationPermissionService {}

class _ReminderScheduleFake extends Fake implements ReminderSchedule {}

void main() {
  setUpAll(() {
    registerFallbackValue(_ReminderScheduleFake());
  });
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockNotificationService notif;
  late _MockPermissionService perm;
  late ReminderScheduler scheduler;
  late ReminderScheduleStore store;
  late NotificationIdFactory idFactory;
  late BirthdayEngine engine;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    notif = _MockNotificationService();
    perm = _MockPermissionService();
    store = ReminderScheduleStore(prefs);
    idFactory = const NotificationIdFactory();
    engine = DefaultBirthdayEngine(const LunarCalendarService());
    scheduler = ReminderScheduler(
      engine: engine,
      idFactory: idFactory,
      notificationService: notif,
      permissionService: perm,
      store: store,
    );

    when(() => perm.query()).thenAnswer(
      (_) async => const NotificationCapabilities(
        postNotifications: true,
        exactAlarms: true,
      ),
    );
    when(
      () => notif.scheduleReminder(
        any(),
        avatarBytes: any(named: 'avatarBytes'),
        exact: any(named: 'exact'),
      ),
    ).thenAnswer((_) async => true);
    when(
      () => notif.isNotificationPending(any()),
    ).thenAnswer((_) async => true);
    when(() => notif.cancel(any())).thenAnswer((_) async => true);
  });

  Birthday make({
    required String id,
    required DateTime solar,
    bool recurring = true,
    bool notifEnabled = true,
    int daysBefore = 0,
    TimeOfDay time = const TimeOfDay(hour: 9, minute: 0),
    String relationship = 'bạn',
    String name = 'Test',
    String? nickname,
    String? gender = 'khác',
  }) {
    return Birthday(
      id: id,
      name: name,
      nickname: nickname,
      gender: gender,
      solarBirthday: solar,
      lunarBirthday: LunarDateTime.fromDateTime(solar),
      calendarType: CalendarType.solar,
      remindBeforeDays: daysBefore,
      remindTime: time,
      repeatAnnually: recurring,
      isRecurringNotificationEnabled: notifEnabled,
      note: null,
      relationship: relationship,
      avatarBase64: null,
    );
  }

  // ---------------------------------------------------------------------------
  // The 15 V3 acceptance cases
  // ---------------------------------------------------------------------------

  test('1. recurring → exactly 1 active schedule entry', () async {
    final b = make(id: 'p1', solar: DateTime(2000, 5, 15));
    final result = await scheduler.scheduleNextAnnualReminder(b);
    expect(result.isOk, isTrue);
    expect(result.scheduledCount, 1);
    final entries = store.loadAll();
    expect(entries.length, 1);
    expect(
      entries.values.first.scheduleKey,
      ReminderScheduler.scheduleKeyFor(birthdayId: 'p1'),
    );
  });

  test('2. non-recurring → 1 schedule (still only one pending)', () async {
    final b = make(id: 'p2', solar: DateTime(2000, 5, 15), recurring: false);
    final result = await scheduler.scheduleNextAnnualReminder(b);
    expect(result.isOk, isTrue);
    expect(result.scheduledCount, 1);
    expect(store.loadAll().length, 1);
  });

  test('3. zero-day reminder uses same year before reminder time', () {
    final b = make(
      id: 'p3',
      solar: DateTime(2000, 10, 27),
      daysBefore: 0,
      time: const TimeOfDay(hour: 7, minute: 0),
    );
    final occurrence = ReminderScheduler.buildNextOccurrence(
      b,
      DateTime(2026, 10, 27, 6),
      engine: engine,
      rule: ReminderRule.fromBirthday(b),
    );
    expect(occurrence!.scheduledAt, DateTime(2026, 10, 27, 7));
  });

  test('3b. zero-day reminder advances a year after reminder time', () {
    final b = make(
      id: 'p3b',
      solar: DateTime(2000, 10, 27),
      daysBefore: 0,
      time: const TimeOfDay(hour: 7, minute: 0),
    );
    final occurrence = ReminderScheduler.buildNextOccurrence(
      b,
      DateTime(2026, 10, 27, 8),
      engine: engine,
      rule: ReminderRule.fromBirthday(b),
    );
    expect(occurrence!.scheduledAt, DateTime(2027, 10, 27, 7));
  });

  test('3c. two-day reminder subtracts two calendar days', () {
    final b = make(
      id: 'p3c',
      solar: DateTime(2000, 10, 27),
      daysBefore: 2,
      time: const TimeOfDay(hour: 7, minute: 0),
    );
    final occurrence = ReminderScheduler.buildNextOccurrence(
      b,
      DateTime(2026, 9, 1),
      engine: engine,
      rule: ReminderRule.fromBirthday(b),
    );
    expect(occurrence!.scheduledAt, DateTime(2026, 10, 25, 7));
  });

  test('4. lunar birthday → next correct lunar date', () async {
    final b = make(id: 'p4', solar: DateTime(2000, 3, 15));
    final result = await scheduler.scheduleNextAnnualReminder(b);
    expect(result.isOk, isTrue);
    expect(result.scheduledAt!.isAfter(DateTime.now()), isTrue);
  });

  test('5. Feb 29 birthday schedules a future year correctly', () async {
    final b = make(id: 'p5', solar: DateTime(2000, 2, 29));
    final result = await scheduler.scheduleNextAnnualReminder(b);
    expect(result.isOk, isTrue);
    expect(result.scheduledAt!.isAfter(DateTime.now()), isTrue);
  });

  test('6. migration v2 → v3 keeps only 1 entry per birthday', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store2 = ReminderScheduleStore(prefs);
    final now = DateTime.now();
    final upcoming = now.add(const Duration(days: 10));
    final later = now.add(const Duration(days: 30));
    final farFuture = now.add(const Duration(days: 365));
    await prefs.setStringList('reminder_managed_ids', [
      'birthday:p6:year:${now.year}:primary|111',
      'birthday:p6:year:${now.year + 1}:primary|222',
      'birthday:p6:year:${now.year + 2}:primary|333',
      'birthday:p6-orphan:year:${now.year}:primary|444',
    ]);
    await prefs.setString(
      'reminder_schedule_fingerprints',
      '{"birthday:p6:year:${now.year}:primary":"a","birthday:p6:year:${now.year + 1}:primary":"b","birthday:p6:year:${now.year + 2}:primary":"c","birthday:p6-orphan:year:${now.year}:primary":"d"}',
    );
    await prefs.setString(
      'reminder_schedule_details_v1',
      '{"birthday:p6:year:${now.year}:primary":{"birthdayId":"p6","scheduledAt":"${upcoming.toIso8601String()}","exact":true},"birthday:p6:year:${now.year + 1}:primary":{"birthdayId":"p6","scheduledAt":"${later.toIso8601String()}","exact":true},"birthday:p6:year:${now.year + 2}:primary":{"birthdayId":"p6","scheduledAt":"${farFuture.toIso8601String()}","exact":true},"birthday:p6-orphan:year:${now.year}:primary":{"birthdayId":"p6-orphan","scheduledAt":"${upcoming.toIso8601String()}","exact":true}}',
    );
    await prefs.setInt('reminder_schedule_schema_version', 2);

    final migrator = LegacyToV3Migrator(
      store: store2,
      notificationService: notif,
    );
    final cancelled = await migrator.runIfNeeded();

    expect(cancelled, 2);
    verify(() => notif.cancel(222)).called(1);
    verify(() => notif.cancel(333)).called(1);
    verifyNever(() => notif.cancel(111));
    final all = store2.loadAll();
    // v3 keeps ONE entry per birthdayId found in the store. The
    // orphan birthday also gets a survivor — the reconciler will
    // cancel it later when the live birthday set does not contain
    // it.
    expect(all.length, 2);
    expect(
      all.values.map((e) => e.birthdayId).toSet(),
      equals({'p6', 'p6-orphan'}),
    );
    expect(
      all.values.first.scheduleKey,
      ReminderScheduler.scheduleKeyFor(birthdayId: 'p6'),
    );
  });

  test(
    '7. existing reminder + reschedule for same birthday = 1 entry',
    () async {
      final b = make(id: 'p7', solar: DateTime(2000, 6, 1));
      final first = await scheduler.scheduleNextAnnualReminder(b);
      final second = await scheduler.scheduleNextAnnualReminder(b);
      expect(first.isOk && second.isOk, isTrue);
      expect(store.loadAll().length, 1);
    },
  );

  test('8. test notification id 0x6E5F00D is preserved by migrator', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store3 = ReminderScheduleStore(prefs);
    await prefs.setStringList('reminder_managed_ids', [
      'birthday:ignore:year:2025:primary|${NotificationService.testNotificationId}',
    ]);
    await prefs.setString(
      'reminder_schedule_fingerprints',
      '{"birthday:ignore:year:2025:primary":"x"}',
    );
    await prefs.setString(
      'reminder_schedule_details_v1',
      '{"birthday:ignore:year:2025:primary":{"birthdayId":"ignore","scheduledAt":"${DateTime.now().add(const Duration(days: 1)).toIso8601String()}","exact":true}}',
    );
    await prefs.setInt('reminder_schedule_schema_version', 2);
    final migrator = LegacyToV3Migrator(
      store: store3,
      notificationService: notif,
    );
    await migrator.runIfNeeded();
    verifyNever(() => notif.cancel(NotificationService.testNotificationId));
  });

  test('9. reschedule for same birthday keeps exactly 1 entry', () async {
    final b = make(id: 'p9', solar: DateTime(2000, 7, 1));
    final first = await scheduler.scheduleNextAnnualReminder(b);
    final second = await scheduler.scheduleNextAnnualReminder(b);
    expect(first.isOk && second.isOk, isTrue);
    expect(store.loadAll().length, 1);
    // Old managed id should have been cancelled during the second call.
    verify(() => notif.cancel(first.notificationId!)).called(1);
  });

  test('10. maintenance tick reschedules when no future pending', () async {
    final b = make(id: 'p10', solar: DateTime(2000, 8, 1));
    await scheduler.scheduleNextAnnualReminder(b);
    final entry = store.loadAll().values.first;
    final pastScheduledAt = DateTime(2020, 1, 1);
    SharedPreferences.setMockInitialValues({
      'reminder_schedule_schema_version': 3,
      'reminder_managed_ids': ['${entry.scheduleKey}|${entry.notificationId}'],
      'reminder_schedule_fingerprints': '{"${entry.scheduleKey}":"x"}',
      'reminder_schedule_details_v1':
          '{"${entry.scheduleKey}":{"birthdayId":"p10","scheduledAt":"${pastScheduledAt.toIso8601String()}","exact":true}}',
    });
    final prefs = await SharedPreferences.getInstance();
    final store4 = ReminderScheduleStore(prefs);
    final scheduler2 = ReminderScheduler(
      engine: engine,
      idFactory: idFactory,
      notificationService: notif,
      permissionService: perm,
      store: store4,
    );
    await scheduler2.scheduleNextAnnualReminder(b);
    final after = store4.loadAll();
    expect(after.length, 1);
    expect(after.values.first.scheduledAt!.isAfter(DateTime.now()), isTrue);
  });

  test('11. edit (remindBeforeDays) keeps at most 1 entry', () async {
    final b0 = make(id: 'p11', solar: DateTime(2000, 9, 1));
    await scheduler.scheduleNextAnnualReminder(b0);
    final b1 = Birthday(
      id: 'p11',
      name: 'Test',
      nickname: null,
      gender: 'khác',
      solarBirthday: DateTime(2000, 9, 1),
      lunarBirthday: LunarDateTime.fromDateTime(DateTime(2000, 9, 1)),
      calendarType: CalendarType.solar,
      remindBeforeDays: 2,
      remindTime: const TimeOfDay(hour: 8, minute: 0),
      repeatAnnually: true,
      isRecurringNotificationEnabled: true,
      note: null,
      relationship: 'bạn',
      avatarBase64: null,
    );
    await scheduler.scheduleNextAnnualReminder(b1);
    expect(store.loadAll().length, 1);
  });

  test('12. soft delete cancels managed reminder', () async {
    final b = make(id: 'p12', solar: DateTime(2000, 10, 1));
    await scheduler.scheduleNextAnnualReminder(b);
    await scheduler.cancelAllFor('p12');
    expect(store.loadAll().isEmpty, isTrue);
    verify(() => notif.cancel(any())).called(greaterThan(0));
  });

  test('13. restart retains schedule (loaded from store)', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store5 = ReminderScheduleStore(prefs);
    final s1 = ReminderScheduler(
      engine: engine,
      idFactory: idFactory,
      notificationService: notif,
      permissionService: perm,
      store: store5,
    );
    final b = make(id: 'p13', solar: DateTime(2000, 11, 1));
    await s1.scheduleNextAnnualReminder(b);

    final store6 = ReminderScheduleStore(prefs);
    final entries = store6.loadAll();
    expect(entries.length, 1);
    expect(entries.values.first.birthdayId, 'p13');
  });

  test('14. UI never says "kỳ nhắc"', () {
    final detailView =
        File('lib/views/birthday_detail_view.dart').readAsStringSync();
    expect(
      detailView.contains('kỳ nhắc'),
      isFalse,
      reason: 'detail view must not contain "kỳ nhắc" copy',
    );
  });

  test('15. "Bật thông báo định kỳ" UI option removed from add/edit view', () {
    final src =
        File('lib/views/birthday_add_edit_view.dart').readAsStringSync();
    expect(
      src.contains('Bật thông báo định kỳ'),
      isFalse,
      reason: 'add/edit view must not contain "Bật thông báo định kỳ" label',
    );
    expect(
      src.contains('Bật thông báo'),
      isTrue,
      reason: 'add/edit view must contain new "Bật thông báo" label',
    );
  });
}
