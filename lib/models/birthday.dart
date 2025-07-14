import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart';

enum CalendarType { solar, lunar }

class LunarDateTime {
  final int day;
  final int month;
  final int year;

  LunarDateTime({
    required this.day,
    required this.month,
    required this.year,
  });

  factory LunarDateTime.fromDateTime(DateTime dateTime) {
    final lunar = Lunar.fromDate(dateTime);
    return LunarDateTime(
      day: lunar.getDay(),
      month: lunar.getMonth(),
      year: lunar.getYear(),
    );
  }

  DateTime toSolarDateTime() {
    final lunar = Lunar.fromYmd(year, month, day);
    final solar = lunar.getSolar();
    return DateTime(solar.getYear(), solar.getMonth(), solar.getDay());
  }

}


class Birthday {
  final String id;
  final String name;
  final String? avatarBase64;
  final String? gender;
  final String? nickname;
  final String? relationship;
  final DateTime solarBirthday;
  final LunarDateTime lunarBirthday;
  final CalendarType calendarType;
  final int remindBeforeDays;
  final TimeOfDay remindTime;
  bool isRecurringNotificationEnabled;
  final bool repeatAnnually;
  final String? note;

  Birthday({
    required this.id,
    required this.name,
    this.avatarBase64,
    this.gender,
    this.nickname,
    this.relationship,
    required this.solarBirthday,
    required this.lunarBirthday,
    required this.calendarType,
    required this.remindBeforeDays,
    required this.remindTime,
    this.isRecurringNotificationEnabled = true,
    this.repeatAnnually = true,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatarBase64': avatarBase64,
      'gender': gender,
      'nickname': nickname,
      'relationship': relationship,
      'solarBirthday': solarBirthday.toIso8601String(),
      'lunarDay': lunarBirthday.day,
      'lunarMonth': lunarBirthday.month,
      'lunarYear': lunarBirthday.year,
      'calendarType': calendarType.toString(),
      'remindBeforeDays': remindBeforeDays,
      'remindTime': '${remindTime.hour}:${remindTime.minute}',
      'isRecurringNotificationEnabled': isRecurringNotificationEnabled ? 1 : 0,
      'repeatAnnually': repeatAnnually ? 1 : 0,
      'note': note,
    };
  }

  factory Birthday.fromMap(Map<String, dynamic> map) {
    return Birthday(
      id: map['id'],
      name: map['name'],
      avatarBase64: map['avatarBase64'],
      gender: map['gender'],
      nickname: map['nickname'],
      relationship: map['relationship'],
      solarBirthday: DateTime.parse(map['solarBirthday']),
      lunarBirthday: LunarDateTime(
        day: map['lunarDay'],
        month: map['lunarMonth'],
        year: map['lunarYear'],
      ),
      calendarType: CalendarType.values.firstWhere((e) => e.toString() == map['calendarType']),
      remindBeforeDays: map['remindBeforeDays'],
      remindTime: TimeOfDay(
        hour: int.parse(map['remindTime'].split(':')[0]),
        minute: int.parse(map['remindTime'].split(':')[1]),
      ),
      isRecurringNotificationEnabled: map['isRecurringNotificationEnabled'] == 1,
      repeatAnnually: map['repeatAnnually'] == 1,
      note: map['note'],
    );
  }
}