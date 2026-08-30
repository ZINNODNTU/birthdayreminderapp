import 'package:birthdayreminderapp/features/reminders/domain/birthday_notification_formatter.dart';
import 'package:birthdayreminderapp/models/birthday.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const formatter = BirthdayNotificationFormatter();

  Birthday makeHien({int year = 2004, int month = 10, int day = 27}) =>
      Birthday(
        id: 'h',
        name: 'Hiền',
        nickname: 'điều dưỡng',
        gender: 'Nữ',
        relationship: 'Bạn',
        solarBirthday: DateTime(year, month, day),
        lunarBirthday: LunarDateTime(day: 14, month: 9, year: year),
        calendarType: CalendarType.solar,
        remindBeforeDays: 0,
        remindTime: const TimeOfDay(hour: 8, minute: 0),
        isRecurringNotificationEnabled: true,
        repeatAnnually: true,
      );

  test('age is computed against occurrence year, not current year', () {
    final b = makeHien(year: 2004, month: 10, day: 27);
    final next = DateTime(2026, 10, 27);
    expect(formatter.ageForOccurrence(b, next), 22);
    final prev = DateTime(2024, 10, 27);
    expect(formatter.ageForOccurrence(b, prev), 20);
  });

  test('age is shown for current-year future birthday', () {
    final b = makeHien(year: 2004, month: 10, day: 27);
    final now = DateTime.now();
    final occ = DateTime(now.year + 2, 10, 27);
    final payload = formatter.buildForOccurrence(birthday: b, occurrence: occ);
    expect(payload.title, contains('Sắp đến sinh nhật Hiền'));
    expect(payload.body, contains('27/10'));
    expect(formatter.ageForOccurrence(b, occ), occ.year - b.solarBirthday.year);
  });

  test('future branch contains the formatted date dd/MM', () {
    final b = makeHien(year: 2004, month: 10, day: 27);
    final occ = DateTime(2030, 10, 27);
    final payload = formatter.buildForOccurrence(birthday: b, occurrence: occ);
    expect(payload.title, contains('Sắp đến sinh nhật Hiền'));
    expect(payload.body, contains('27/10'));
  });

  test('two birthdays do not share content', () {
    final hi = makeHien(year: 2004, month: 10, day: 27);
    final beo = Birthday(
      id: 'b',
      name: 'Béo',
      solarBirthday: DateTime(2000, 1, 15),
      lunarBirthday: LunarDateTime(day: 1, month: 1, year: 2000),
      calendarType: CalendarType.solar,
      remindBeforeDays: 0,
      remindTime: const TimeOfDay(hour: 8, minute: 0),
      isRecurringNotificationEnabled: true,
      repeatAnnually: true,
    );
    final hiPayload = formatter.buildForOccurrence(
      birthday: hi,
      occurrence: DateTime(2026, 10, 27),
    );
    final beoPayload = formatter.buildForOccurrence(
      birthday: beo,
      occurrence: DateTime(2026, 1, 15),
    );
    expect(hiPayload.containsName('Hiền'), isTrue);
    expect(hiPayload.containsName('Béo'), isFalse);
    expect(beoPayload.containsName('Béo'), isTrue);
    expect(beoPayload.containsName('Hiền'), isFalse);
  });
}
