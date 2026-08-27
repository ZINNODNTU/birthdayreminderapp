import 'package:birthdayreminderapp/models/birthday.dart';
import 'package:birthdayreminderapp/utils/lunar_converter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Birthday serializes and restores every persisted field', () {
    final birthday = Birthday(
      id: 'birthday-1',
      name: 'Nguyễn An',
      avatarBase64: 'aGVsbG8=',
      gender: 'Nam',
      nickname: 'An',
      relationship: 'Bạn bè',
      solarBirthday: DateTime(1995, 7, 14, 8, 30),
      lunarBirthday: LunarDateTime(day: 17, month: 6, year: 1995),
      calendarType: CalendarType.lunar,
      remindBeforeDays: 3,
      remindTime: const TimeOfDay(hour: 9, minute: 5),
      isRecurringNotificationEnabled: false,
      repeatAnnually: true,
      note: 'Gọi điện chúc mừng',
    );

    final map = birthday.toMap();
    final restored = Birthday.fromMap(map);

    expect(map['calendarType'], 'CalendarType.lunar');
    expect(map['remindTime'], '9:5');
    expect(map['isRecurringNotificationEnabled'], 0);
    expect(restored.id, birthday.id);
    expect(restored.name, birthday.name);
    expect(restored.avatarBase64, birthday.avatarBase64);
    expect(restored.gender, birthday.gender);
    expect(restored.nickname, birthday.nickname);
    expect(restored.relationship, birthday.relationship);
    expect(restored.solarBirthday, birthday.solarBirthday);
    expect(restored.lunarBirthday.day, 17);
    expect(restored.lunarBirthday.month, 6);
    expect(restored.lunarBirthday.year, 1995);
    expect(restored.calendarType, CalendarType.lunar);
    expect(restored.remindBeforeDays, 3);
    expect(restored.remindTime, const TimeOfDay(hour: 9, minute: 5));
    expect(restored.isRecurringNotificationEnabled, isFalse);
    expect(restored.repeatAnnually, isTrue);
    expect(restored.note, birthday.note);
  });

  test('LunarConverter converts Vietnamese Lunar New Year 2024', () {
    final lunar = LunarConverter.toLunar(DateTime(2024, 2, 10));

    expect(lunar.day, 1);
    expect(lunar.month, 1);
    expect(lunar.year, 2024);
    expect(LunarConverter.toSolar(lunar), DateTime(2024, 2, 10));
  });
}
