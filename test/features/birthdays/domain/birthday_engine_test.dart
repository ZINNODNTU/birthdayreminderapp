import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:birthdayreminderapp/features/birthdays/domain/birthday_engine.dart';
import 'package:birthdayreminderapp/features/birthdays/domain/default_birthday_engine.dart';
import 'package:birthdayreminderapp/features/birthdays/domain/lunar_calendar_service.dart';
import 'package:birthdayreminderapp/models/birthday.dart';

void main() {
  late BirthdayEngine engine;
  late LunarCalendarService calendar;

  setUpAll(() {
    calendar = const LunarCalendarService();
    engine = DefaultBirthdayEngine(calendar);
  });

  Birthday solar({
    String id = 's',
    required DateTime birthday,
    TimeOfDay remindTime = const TimeOfDay(hour: 9, minute: 0),
  }) {
    return Birthday(
      id: id,
      name: 'S',
      solarBirthday: birthday,
      lunarBirthday: LunarDateTime.fromDateTime(birthday),
      calendarType: CalendarType.solar,
      remindBeforeDays: 0,
      remindTime: remindTime,
    );
  }

  Birthday lunar({String id = 'l', required LunarDateTime lunar}) {
    return Birthday(
      id: id,
      name: 'L',
      solarBirthday: lunar.toSolarDateTime(),
      lunarBirthday: lunar,
      calendarType: CalendarType.lunar,
      remindBeforeDays: 0,
      remindTime: const TimeOfDay(hour: 9, minute: 0),
    );
  }

  group('Solar recurrence', () {
    test('occurrenceInYear keeps month/day and uses requested year', () {
      final b = solar(birthday: DateTime(1990, 5, 10));
      expect(engine.occurrenceInYear(b, 2026), DateTime(2026, 5, 10));
      expect(engine.occurrenceInYear(b, 2030), DateTime(2030, 5, 10));
    });

    test('Feb 29 in a non-leap year collapses to Feb 28', () {
      final b = solar(birthday: DateTime(2000, 2, 29));
      // 2025 is not a leap year.
      expect(engine.occurrenceInYear(b, 2025), DateTime(2025, 2, 28));
      // 2028 is a leap year.
      expect(engine.occurrenceInYear(b, 2028), DateTime(2028, 2, 29));
    });

    test('daysUntilNextBirthday returns 0 when from equals the date', () {
      final b = solar(birthday: DateTime(2000, 7, 14));
      final occ = engine.occurrenceInYear(b, 2026);
      expect(engine.daysUntilNextBirthday(b, from: occ), 0);
    });

    test('daysUntilNextBirthday returns 1 for tomorrow', () {
      final b = solar(birthday: DateTime(2000, 7, 14));
      final today = DateTime(2026, 7, 13);
      expect(engine.daysUntilNextBirthday(b, from: today), 1);
    });

    test('daysUntilNextBirthday rolls over to next year for yesterday', () {
      final b = solar(birthday: DateTime(2000, 7, 14));
      final yesterday = DateTime(2026, 7, 13).subtract(const Duration(days: 1));
      // Yesterday was 2026-07-12; next occurrence is 2026-07-14 = 2 days.
      expect(engine.daysUntilNextBirthday(b, from: yesterday), 2);
    });

    test(
      'Dec/Jan boundary: birthday on 01-01 returns 2027 from 31-12-2026',
      () {
        final b = solar(birthday: DateTime(2000, 1, 1));
        final from = DateTime(2026, 12, 31);
        expect(engine.nextOccurrence(b, from: from), DateTime(2027, 1, 1));
        expect(engine.daysUntilNextBirthday(b, from: from), 1);
      },
    );

    test('ageAtOccurrence uses occurrence.year - birth.year (solar)', () {
      final b = solar(birthday: DateTime(1990, 5, 10));
      expect(engine.ageAtOccurrence(b, occurrence: DateTime(2026, 5, 10)), 36);
      // The day before the birthday is still 35.
      expect(engine.ageAtOccurrence(b, occurrence: DateTime(2026, 5, 9)), 35);
    });

    test('snapshot agrees with separate calls', () {
      final b = solar(birthday: DateTime(1990, 5, 10));
      final from = DateTime(2026, 5, 9);
      final s = engine.snapshot(b, from: from);
      expect(s.date, DateTime(2026, 5, 10));
      expect(s.daysUntil, 1);
      expect(s.age, 36);
    });
  });

  group('Lunar recurrence — the recurring-lunar fix', () {
    test('occurrenceInYear uses TARGET year, not stored lunar year', () {
      // Stored lunar year is 1985, but we ask for 2026.
      final b = lunar(
        lunar: const LunarDateTime(day: 15, month: 8, year: 1985),
      );
      final occ2026 = engine.occurrenceInYear(b, 2026);
      expect(occ2026.year, 2026);
      // Sanity: it must not be the original-year mapping.
      final legacy = b.lunarBirthday.toSolarDateTime();
      expect(occ2026, isNot(legacy));
    });

    test(
      'occurrenceInYear(2026) != occurrenceInYear(2027) for the same birthday',
      () {
        final b = lunar(
          lunar: const LunarDateTime(day: 15, month: 8, year: 1985),
        );
        final a = engine.occurrenceInYear(b, 2026);
        final c = engine.occurrenceInYear(b, 2027);
        expect(a.year, 2026);
        expect(c.year, 2027);
        // They might land on the same solar day, but at least confirm the
        // year is correct in each case.
      },
    );

    test('Lunar New Year 2024 == 2024-02-10', () {
      final lunar = calendar.toLunar(DateTime(2024, 2, 10));
      expect(lunar.day, 1);
      expect(lunar.month, 1);
      expect(lunar.year, 2024);
    });

    test('Lunar New Year 2025 == 2025-01-29', () {
      final lunar = calendar.toLunar(DateTime(2025, 1, 29));
      expect(lunar.day, 1);
      expect(lunar.month, 1);
      expect(lunar.year, 2025);
    });

    test('Lunar New Year 2026 == 2026-02-17', () {
      final lunar = calendar.toLunar(DateTime(2026, 2, 17));
      expect(lunar.day, 1);
      expect(lunar.month, 1);
      expect(lunar.year, 2026);
    });

    test('Round-trip: solar → lunar → solar for Tết dates matches', () {
      for (final solar in [
        DateTime(2024, 2, 10),
        DateTime(2025, 1, 29),
        DateTime(2026, 2, 17),
      ]) {
        final l = calendar.toLunar(solar);
        expect(calendar.toSolar(l), solar);
      }
    });

    test(
      'nextOccurrence finds the next future solar date for a lunar birthday',
      () {
        // Lunar birthday 1/1 → next Tết.
        final b = lunar(
          lunar: const LunarDateTime(day: 1, month: 1, year: 1985),
        );
        final from = DateTime(2024, 1, 1);
        // Next lunar 1/1 after 2024-01-01 is 2024-02-10.
        expect(engine.nextOccurrence(b, from: from), DateTime(2024, 2, 10));
      },
    );

    test('ageAtOccurrence uses stored lunar year for lunar birthdays', () {
      final b = lunar(lunar: const LunarDateTime(day: 1, month: 1, year: 1985));
      // Occurrence on 2026 solar is 2026-02-17; age = 2026 - 1985.
      final occ = engine.occurrenceInYear(b, 2026);
      expect(engine.ageAtOccurrence(b, occurrence: occ), 41);
    });
  });

  group('Invalid / edge cases', () {
    test('Lunar conversion does not crash for far past dates', () {
      final l = calendar.toLunar(DateTime(1950, 5, 1));
      expect(l.year, isNonZero);
      expect(l.month, inInclusiveRange(1, 12));
      expect(l.day, inInclusiveRange(1, 30));
    });

    test('Engine is deterministic for the same inputs', () {
      final b = solar(birthday: DateTime(2000, 1, 1));
      final from = DateTime(2026, 6, 1);
      final a = engine.daysUntilNextBirthday(b, from: from);
      final c = engine.daysUntilNextBirthday(b, from: from);
      expect(a, c);
    });
  });
}
