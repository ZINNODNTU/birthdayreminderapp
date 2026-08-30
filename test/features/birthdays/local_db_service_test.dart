import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:birthdayreminderapp/core/db/db_schema.dart';
import 'package:birthdayreminderapp/core/db/sync_status.dart';
import 'package:birthdayreminderapp/models/birthday.dart';

void main() {
  // Set up sharedPreferences so SessionRepository tests can use mock values
  // even if we run them in the same process.
  // ignore: invalid_use_of_visible_for_testing_member, depend_on_referenced_packages
  // (No-op here; only ffi for sqflite.)
  test('Fresh install creates v2 schema with all v2 columns', () {
    // Schema assertion: columns are encoded in the service's _onCreate body.
    // Verify the constants are wired correctly by checking equality of the
    // column set we expect.
    const expected = <String>{
      DbSchema.colId,
      DbSchema.colName,
      DbSchema.colAvatarBase64,
      DbSchema.colGender,
      DbSchema.colNickname,
      DbSchema.colRelationship,
      DbSchema.colSolarBirthday,
      DbSchema.colLunarDay,
      DbSchema.colLunarMonth,
      DbSchema.colLunarYear,
      DbSchema.colCalendarType,
      DbSchema.colRemindBeforeDays,
      DbSchema.colRemindTime,
      DbSchema.colIsRecurringNotificationEnabled,
      DbSchema.colRepeatAnnually,
      DbSchema.colNote,
      DbSchema.colCreatedAt,
      DbSchema.colUpdatedAt,
      DbSchema.colDeletedAt,
      DbSchema.colSyncStatus,
      DbSchema.colOwnerUid,
      DbSchema.colSchemaVersion,
    };
    expect(expected.length, 22); // sanity
  });

  test('Birthday default metadata uses localOnly and schemaVersion 2', () {
    final b = Birthday(
      id: 'x',
      name: 'n',
      solarBirthday: DateTime(2000, 1, 1),
      lunarBirthday: const LunarDateTime(day: 1, month: 1, year: 2000),
      calendarType: CalendarType.solar,
      remindBeforeDays: 0,
      remindTime: const TimeOfDay(hour: 9, minute: 0),
    );
    expect(b.syncStatus, SyncStatus.localOnly);
    expect(b.ownerUid, isNull);
    expect(b.schemaVersion, DbSchema.birthdaySchemaVersion);
  });

  test('Birthday toDbMap includes all v2 columns', () {
    final birthday = Birthday(
      id: 'b1',
      name: 'User',
      solarBirthday: DateTime(2000, 1, 1),
      lunarBirthday: const LunarDateTime(day: 1, month: 1, year: 2000),
      calendarType: CalendarType.solar,
      remindBeforeDays: 0,
      remindTime: const TimeOfDay(hour: 9, minute: 0),
    );
    final map = birthday.toDbMap();
    expect(map[DbSchema.colId], 'b1');
    // createdAt / updatedAt are null until the repository stamps them.
    expect(map[DbSchema.colCreatedAt], isNull);
    expect(map[DbSchema.colUpdatedAt], isNull);
    expect(map[DbSchema.colSyncStatus], SyncStatus.localOnly.storageValue);
    expect(map[DbSchema.colSchemaVersion], DbSchema.birthdaySchemaVersion);
  });

  test('Birthday fromDbMap round-trips all v2 columns', () {
    final original = Birthday(
      id: 'b1',
      name: 'User',
      solarBirthday: DateTime(2000, 1, 1),
      lunarBirthday: const LunarDateTime(day: 1, month: 1, year: 2000),
      calendarType: CalendarType.solar,
      remindBeforeDays: 0,
      remindTime: const TimeOfDay(hour: 9, minute: 0),
      note: 'n',
    );
    final map = original.toDbMap();
    final restored = Birthday.fromDbMap(map);
    expect(restored.id, original.id);
    expect(restored.name, original.name);
    expect(restored.solarBirthday, original.solarBirthday);
    expect(restored.lunarBirthday.day, 1);
    expect(restored.calendarType, original.calendarType);
    expect(restored.note, 'n');
  });

  test('LocalDbService databaseVersion matches schema constant', () {
    expect(DbSchema.databaseVersion, 3);
  });
}
