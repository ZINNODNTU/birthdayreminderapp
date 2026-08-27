import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:birthdayreminderapp/features/birthdays/domain/default_birthday_engine.dart';
import 'package:birthdayreminderapp/features/birthdays/domain/lunar_calendar_service.dart';
import 'package:birthdayreminderapp/features/reminders/domain/reminder_rule.dart';
import 'package:birthdayreminderapp/features/reminders/services/notification_id_factory.dart';
import 'package:birthdayreminderapp/features/reminders/services/reminder_scheduler.dart';
import 'package:birthdayreminderapp/models/birthday.dart';

void main() {
  const idFactory = NotificationIdFactory();
  const builder = ReminderScheduleBuilder();
  const engine = DefaultBirthdayEngine(LunarCalendarService());

  Birthday solar(DateTime when) => Birthday(
    id: 'b1',
    name: 'An',
    solarBirthday: DateTime(2000, when.month, when.day),
    lunarBirthday: LunarDateTime.fromDateTime(when),
    calendarType: CalendarType.solar,
    remindBeforeDays: 0,
    remindTime: const TimeOfDay(hour: 8, minute: 0),
    isRecurringNotificationEnabled: true,
  );

  Birthday lunar(LunarDateTime lunar) => Birthday(
    id: 'l1',
    name: 'Lan',
    solarBirthday: lunar.toSolarDateTime(),
    lunarBirthday: lunar,
    calendarType: CalendarType.lunar,
    remindBeforeDays: 0,
    remindTime: const TimeOfDay(hour: 8, minute: 0),
    isRecurringNotificationEnabled: true,
  );

  group('ReminderScheduleBuilder', () {
    test('solar birthday: scheduledAt = occurrence 08:00', () {
      final b = solar(DateTime(2026, 7, 14));
      final schedule =
          builder.build(
            birthday: b,
            rule: ReminderRule.fromBirthday(b),
            engine: engine,
            idFactory: idFactory,
            now: DateTime(2026, 7, 1),
          )!;
      expect(schedule.scheduledAt, DateTime(2026, 7, 14, 8, 0));
      expect(schedule.occurrenceDate, DateTime(2026, 7, 14));
    });

    test('remindBeforeDays subtracts days', () {
      final b = solar(DateTime(2026, 7, 14));
      final rule = ReminderRule(
        daysBefore: 3,
        time: const TimeOfDay(hour: 8, minute: 0),
        enabled: true,
      );
      final schedule =
          builder.build(
            birthday: b,
            rule: rule,
            engine: engine,
            idFactory: idFactory,
            now: DateTime(2026, 7, 1),
          )!;
      expect(schedule.scheduledAt, DateTime(2026, 7, 11, 8, 0));
    });

    test('past reminder rolls forward to next occurrence', () {
      final b = solar(DateTime(2026, 7, 14));
      final schedule =
          builder.build(
            birthday: b,
            rule: ReminderRule.fromBirthday(b),
            engine: engine,
            idFactory: idFactory,
            now: DateTime(2026, 7, 16),
          )!;
      // Already past in 2026 → next year.
      expect(schedule.occurrenceDate, DateTime(2027, 7, 14));
    });

    test('lunar birthday uses engine target-year conversion', () {
      // Lunar 15/8/1985 → Tết-class shift.
      final b = lunar(const LunarDateTime(day: 15, month: 8, year: 1985));
      final schedule =
          builder.build(
            birthday: b,
            rule: ReminderRule.fromBirthday(b),
            engine: engine,
            idFactory: idFactory,
            now: DateTime(2026, 1, 1),
          )!;
      // Occurrence must land in 2026, not 1985.
      expect(schedule.occurrenceDate.year, 2026);
    });

    test('scheduleKey is stable for same birthday+rule', () {
      final b = solar(DateTime(2026, 7, 14));
      final s1 = ReminderScheduler.scheduleKeyFor(
        b.id,
        ReminderRule.fromBirthday(b),
      );
      final s2 = ReminderScheduler.scheduleKeyFor(
        b.id,
        ReminderRule.fromBirthday(b),
      );
      expect(s1, s2);
    });

    test('notificationId is positive', () {
      final b = solar(DateTime(2026, 7, 14));
      final schedule =
          builder.build(
            birthday: b,
            rule: ReminderRule.fromBirthday(b),
            engine: engine,
            idFactory: idFactory,
            now: DateTime(2026, 7, 1),
          )!;
      expect(schedule.notificationId, greaterThan(0));
    });
  });
}
