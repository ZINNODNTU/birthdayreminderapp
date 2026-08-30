import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart';

import '../core/db/db_schema.dart';
import '../core/db/sync_status.dart';

enum CalendarType { solar, lunar }

class LunarDateTime {
  final int day;
  final int month;
  final int year;

  const LunarDateTime({
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

  // Phase 2: sync-ready metadata. Existing local records had no real values
  // so they get filled with the migration time on upgrade.
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;
  final String? ownerUid;
  final int schemaVersion;

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
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.syncStatus = SyncStatus.localOnly,
    this.ownerUid,
    this.schemaVersion = DbSchema.birthdaySchemaVersion,
  });

  /// Generic map representation. Kept for backward compatibility with the
  /// existing widget tests; new code should prefer [toDbMap].
  Map<String, dynamic> toMap() => toDbMap();

  /// Generic parser. Tries to read metadata columns if present, otherwise
  /// leaves them null/default.
  factory Birthday.fromMap(Map<String, dynamic> map) => fromDbMap(map);

  Map<String, dynamic> toDbMap() {
    return {
      DbSchema.colId: id,
      DbSchema.colName: name,
      DbSchema.colAvatarBase64: avatarBase64,
      DbSchema.colGender: gender,
      DbSchema.colNickname: nickname,
      DbSchema.colRelationship: relationship,
      DbSchema.colSolarBirthday: solarBirthday.toIso8601String(),
      DbSchema.colLunarDay: lunarBirthday.day,
      DbSchema.colLunarMonth: lunarBirthday.month,
      DbSchema.colLunarYear: lunarBirthday.year,
      DbSchema.colCalendarType: calendarType.toString(),
      DbSchema.colRemindBeforeDays: remindBeforeDays,
      DbSchema.colRemindTime: '${remindTime.hour}:${remindTime.minute}',
      DbSchema.colIsRecurringNotificationEnabled:
          isRecurringNotificationEnabled ? 1 : 0,
      DbSchema.colRepeatAnnually: repeatAnnually ? 1 : 0,
      DbSchema.colNote: note,
      DbSchema.colCreatedAt: createdAt?.toIso8601String(),
      DbSchema.colUpdatedAt: updatedAt?.toIso8601String(),
      DbSchema.colDeletedAt: deletedAt?.toIso8601String(),
      DbSchema.colSyncStatus: syncStatus.storageValue,
      DbSchema.colOwnerUid: ownerUid,
      DbSchema.colSchemaVersion: schemaVersion,
    };
  }

  static Birthday fromDbMap(Map<String, dynamic> map) {
    return Birthday(
      id: map[DbSchema.colId] as String,
      name: map[DbSchema.colName] as String,
      avatarBase64: map[DbSchema.colAvatarBase64] as String?,
      gender: map[DbSchema.colGender] as String?,
      nickname: map[DbSchema.colNickname] as String?,
      relationship: map[DbSchema.colRelationship] as String?,
      solarBirthday: DateTime.parse(map[DbSchema.colSolarBirthday] as String),
      lunarBirthday: LunarDateTime(
        day: map[DbSchema.colLunarDay] as int,
        month: map[DbSchema.colLunarMonth] as int,
        year: map[DbSchema.colLunarYear] as int,
      ),
      calendarType: CalendarType.values.firstWhere(
        (e) => e.toString() == map[DbSchema.colCalendarType],
      ),
      remindBeforeDays: _parseIntOrZero(map[DbSchema.colRemindBeforeDays]),
      remindTime: TimeOfDay(
        hour: int.parse(map[DbSchema.colRemindTime].toString().split(':')[0]),
        minute: int.parse(map[DbSchema.colRemindTime].toString().split(':')[1]),
      ),
      isRecurringNotificationEnabled:
          map[DbSchema.colIsRecurringNotificationEnabled] == 1,
      repeatAnnually: map[DbSchema.colRepeatAnnually] == 1,
      note: map[DbSchema.colNote] as String?,
      createdAt: _parseDateOrNull(map[DbSchema.colCreatedAt]),
      updatedAt: _parseDateOrNull(map[DbSchema.colUpdatedAt]),
      deletedAt: _parseDateOrNull(map[DbSchema.colDeletedAt]),
      syncStatus: SyncStatus.fromStorage(
        map[DbSchema.colSyncStatus] as String?,
      ),
      ownerUid: map[DbSchema.colOwnerUid] as String?,
      schemaVersion:
          (map[DbSchema.colSchemaVersion] as int?) ??
          DbSchema.birthdaySchemaVersion,
    );
  }

  static int _parseIntOrZero(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _parseDateOrNull(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.parse(value);
    return null;
  }
}
