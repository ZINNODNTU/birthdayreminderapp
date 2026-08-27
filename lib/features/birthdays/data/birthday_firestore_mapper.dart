import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/birthday.dart';

/// Bidirectional converter between the on-disk [Birthday] model and the
/// canonical Firestore document under `/users/{uid}/birthdays/{id}`.
///
/// The two schemas are intentionally different: SQLite is denormalised
/// for indexing and local-first speed, while the Firestore schema is
/// normalised for security-rule validation. Do not collapse the two.
class BirthdayFirestoreMapper {
  const BirthdayFirestoreMapper();

  /// Cloud schema version — bump only when a destructive migration is
  /// required. Rules validate this field.
  static const int schemaVersion = 1;

  /// Build the canonical Firestore map for an upsert.
  Map<String, dynamic> toFirestore(Birthday b) {
    return {
      'id': b.id,
      'name': b.name,
      'nickname': b.nickname,
      'gender': b.gender,
      'relationship': b.relationship,
      'calendarType': b.calendarType.name,
      'solarBirthday': Timestamp.fromDate(b.solarBirthday),
      'lunar': {
        'day': b.lunarBirthday.day,
        'month': b.lunarBirthday.month,
        'year': b.lunarBirthday.year,
        // SQLite schema v2 does not persist leap-month state; we
        // default to false until v3 ships. Documented in
        // docs/FIRESTORE_SCHEMA.md.
        'isLeapMonth': false,
      },
      'note': b.note,
      'reminder': {
        'enabled': b.isRecurringNotificationEnabled,
        'daysBefore': b.remindBeforeDays,
        'hour': b.remindTime.hour,
        'minute': b.remindTime.minute,
        'repeatAnnually': b.repeatAnnually,
      },
      'createdAt':
          b.createdAt == null
              ? FieldValue.serverTimestamp()
              : Timestamp.fromDate(b.createdAt!),
      'updatedAt': Timestamp.fromDate(b.updatedAt ?? DateTime.now()),
      'deletedAt':
          b.deletedAt == null ? null : Timestamp.fromDate(b.deletedAt!),
      'schemaVersion': schemaVersion,
    };
  }

  /// Build a [Birthday] from a Firestore snapshot. Returns `null` if
  /// the document is missing or structurally invalid.
  Birthday? fromFirestore(DocumentSnapshot<Map<String, dynamic>> snap) {
    final raw = snap.data();
    if (raw == null) return null;
    final id = (raw['id'] as String?) ?? snap.id;
    final name = raw['name'] as String?;
    if (id.isEmpty || name == null || name.isEmpty) return null;

    final calendarName = raw['calendarType'] as String? ?? 'solar';
    final calendarType = CalendarType.values.firstWhere(
      (c) => c.name == calendarName,
      orElse: () => CalendarType.solar,
    );

    final solarTs = raw['solarBirthday'] as Timestamp?;
    final solar = solarTs?.toDate() ?? DateTime(2000, 1, 1);

    final lunarMap = raw['lunar'] as Map<String, dynamic>?;
    final lunar =
        lunarMap == null
            ? const LunarDateTime(day: 1, month: 1, year: 2000)
            : LunarDateTime(
              day: (lunarMap['day'] as num?)?.toInt() ?? 1,
              month: (lunarMap['month'] as num?)?.toInt() ?? 1,
              year: (lunarMap['year'] as num?)?.toInt() ?? 2000,
            );

    final reminder = raw['reminder'] as Map<String, dynamic>?;
    final hour = (reminder?['hour'] as num?)?.toInt() ?? 9;
    final minute = (reminder?['minute'] as num?)?.toInt() ?? 0;
    final clampedHour = hour.clamp(0, 23);
    final clampedMinute = minute.clamp(0, 59);

    return Birthday(
      id: id,
      name: name,
      solarBirthday: solar,
      lunarBirthday: lunar,
      calendarType: calendarType,
      remindBeforeDays: (reminder?['daysBefore'] as num?)?.toInt() ?? 0,
      remindTime: TimeOfDay(hour: clampedHour, minute: clampedMinute),
      isRecurringNotificationEnabled: reminder?['enabled'] as bool? ?? false,
      repeatAnnually: reminder?['repeatAnnually'] as bool? ?? false,
      nickname: raw['nickname'] as String?,
      gender: raw['gender'] as String?,
      relationship: raw['relationship'] as String?,
      note: raw['note'] as String?,
      createdAt: (raw['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (raw['updatedAt'] as Timestamp?)?.toDate(),
      deletedAt: (raw['deletedAt'] as Timestamp?)?.toDate(),
      schemaVersion: (raw['schemaVersion'] as num?)?.toInt() ?? 1,
    );
  }
}
