import 'package:flutter_test/flutter_test.dart';

import 'package:birthdayreminderapp/features/birthdays/domain/lunar_calendar_service.dart';
import 'package:birthdayreminderapp/models/birthday.dart';

void main() {
  const calendar = LunarCalendarService();

  group('LunarCalendarService', () {
    test('toSolarForYear ignores the stored year and uses the target year', () {
      // Same lunar day/month across two years.
      final a = calendar.toSolarForYear(
        const LunarDateTime(day: 15, month: 8, year: 1900),
        2026,
      );
      final b = calendar.toSolarForYear(
        const LunarDateTime(day: 15, month: 8, year: 1900),
        2027,
      );
      expect(a.year, 2026);
      expect(b.year, 2027);
    });

    test('toSolar honours the stored year when target year is omitted', () {
      final date = calendar.toSolar(
        const LunarDateTime(day: 1, month: 1, year: 1985),
      );
      // 1985 lunar 1/1 = 1985-02-20 (per package).
      expect(date, DateTime(1985, 2, 20));
    });

    test('isLeapLunarMonth reports a leap month for the right year', () {
      // 2020 had a leap 4th month.
      expect(calendar.isLeapLunarMonth(2020, 4), isTrue);
      expect(calendar.isLeapLunarMonth(2020, 5), isFalse);
    });

    test('Round-trip: solar → lunar → solar for Tet dates', () {
      for (final d in [
        DateTime(2024, 2, 10),
        DateTime(2025, 1, 29),
        DateTime(2026, 2, 17),
      ]) {
        expect(calendar.toSolar(calendar.toLunar(d)), d);
      }
    });
  });
}
