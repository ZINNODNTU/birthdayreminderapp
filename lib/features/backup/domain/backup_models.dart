// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/db/sync_status.dart';
import '../../../models/birthday.dart';

const backupSchemaVersion = 1;
const maxBackupBytes = 250 * 1024 * 1024;
const maxExpandedBytes = 500 * 1024 * 1024;
const maxEntries = 5000;
const maxJsonBytes = 20 * 1024 * 1024;
const maxPhotoBytes = 5 * 1024 * 1024;
const maxBirthdays = 10000;

enum RestoreStrategy { merge, replace }

enum RestoreMode { normal, signingMigration }

class RestoreWarning {
  const RestoreWarning(this.code, this.message);
  final String code;
  final String message;
}

class BackupResult {
  const BackupResult({
    required this.bytes,
    required this.fileName,
    required this.birthdayCount,
    required this.photoCount,
    required this.warnings,
  });
  final Uint8List bytes;
  final String fileName;
  final int birthdayCount;
  final int photoCount;
  final List<RestoreWarning> warnings;
}

class RestorePlan {
  const RestorePlan({
    required this.createdAt,
    required this.appVersion,
    required this.records,
    required this.settings,
    required this.photos,
    required this.warnings,
  });
  final DateTime createdAt;
  final String appVersion;
  final List<Birthday> records;
  final Map<String, Object?> settings;
  final Map<String, Uint8List> photos;
  final List<RestoreWarning> warnings;
  int get birthdayCount => records.length;
  int get photoCount => photos.length;
}

class RestoreResult {
  const RestoreResult({
    required this.restored,
    required this.skipped,
    required this.conflicts,
    required this.photosRestored,
    required this.photosFailed,
    required this.warnings,
  });
  final int restored, skipped, conflicts, photosRestored, photosFailed;
  final List<RestoreWarning> warnings;
}

Map<String, Object?> birthdayToBackupJson(
  Birthday b, {
  String? photoFile,
  String? photoHash,
  int? photoSize,
}) => {
  'id': b.id,
  'name': b.name,
  'nickname': b.nickname,
  'gender': b.gender,
  'relationship': b.relationship,
  'solarBirthday': b.solarBirthday.toIso8601String(),
  'lunarDay': b.lunarBirthday.day,
  'lunarMonth': b.lunarBirthday.month,
  'lunarYear': b.lunarBirthday.year,
  'calendarType': b.calendarType.name,
  'remindBeforeDays': b.remindBeforeDays,
  'remindHour': b.remindTime.hour,
  'remindMinute': b.remindTime.minute,
  'notificationEnabled': b.isRecurringNotificationEnabled,
  'repeatAnnually': b.repeatAnnually,
  'note': b.note,
  'createdAt': b.createdAt?.toIso8601String(),
  'updatedAt': b.updatedAt?.toIso8601String(),
  'deletedAt': b.deletedAt?.toIso8601String(),
  'syncStatus': b.syncStatus.storageValue,
  'ownerUid': b.ownerUid,
  'schemaVersion': b.schemaVersion,
  'photoBackupFile': photoFile,
  'photoMimeType': photoFile == null ? null : 'image/jpeg',
  'photoByteSize': photoSize,
  'photoHash': photoHash,
};

Birthday birthdayFromBackupJson(
  Map<String, dynamic> j, {
  String? avatarBase64,
  RestoreMode mode = RestoreMode.signingMigration,
}) {
  T need<T>(String key) {
    final v = j[key];
    if (v is! T) throw FormatException('Invalid $key');
    return v;
  }

  DateTime? date(String key) {
    final v = j[key];
    if (v == null) return null;
    if (v is! String) throw FormatException('Invalid $key');
    return DateTime.parse(v);
  }

  final calendar =
      CalendarType.values
          .where((e) => e.name == need<String>('calendarType'))
          .firstOrNull;
  final sync =
      SyncStatus.values
          .where((e) => e.storageValue == need<String>('syncStatus'))
          .firstOrNull;
  if (calendar == null || sync == null)
    throw const FormatException('Invalid enum');
  return Birthday(
    id: need<String>('id'),
    name: need<String>('name'),
    avatarBase64: avatarBase64,
    nickname: j['nickname'] as String?,
    gender: j['gender'] as String?,
    relationship: j['relationship'] as String?,
    solarBirthday: DateTime.parse(need<String>('solarBirthday')),
    lunarBirthday: LunarDateTime(
      day: need<int>('lunarDay'),
      month: need<int>('lunarMonth'),
      year: need<int>('lunarYear'),
    ),
    calendarType: calendar,
    remindBeforeDays: need<int>('remindBeforeDays'),
    remindTime: TimeOfDay(
      hour: need<int>('remindHour'),
      minute: need<int>('remindMinute'),
    ),
    isRecurringNotificationEnabled: need<bool>('notificationEnabled'),
    repeatAnnually: need<bool>('repeatAnnually'),
    note: j['note'] as String?,
    createdAt: date('createdAt'),
    updatedAt: date('updatedAt'),
    deletedAt: date('deletedAt'),
    syncStatus:
        mode == RestoreMode.signingMigration ? SyncStatus.localOnly : sync,
    ownerUid:
        mode == RestoreMode.signingMigration ? null : j['ownerUid'] as String?,
    schemaVersion: need<int>('schemaVersion'),
  );
}

String canonicalJson(Object value) => jsonEncode(value);
