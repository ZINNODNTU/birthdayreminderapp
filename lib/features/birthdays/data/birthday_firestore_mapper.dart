import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/birthday.dart';
import '../services/birthday_photo_service.dart';

/// Cloud-side photo payload extracted from a [Birthday]. Always built
/// at the moment of an upsert so the encoded bytes never outlive a
/// single sync cycle.
class BirthdayCloudPhoto {
  const BirthdayCloudPhoto({
    required this.photoBase64,
    required this.mimeType,
    required this.byteSize,
    required this.hash,
    required this.updatedAt,
  });

  final String photoBase64;
  final String mimeType;
  final int byteSize;
  final String hash;
  final DateTime updatedAt;

  BirthdayCloudPhoto.fromEncoded(EncodedBirthdayPhoto e, {DateTime? now})
    : photoBase64 = e.base64,
      mimeType = e.mimeType,
      byteSize = e.byteSize,
      hash = e.hash,
      updatedAt = now ?? DateTime.now();
}

/// What [BirthdayFirestoreMapper.fromFirestore] returns when there is
/// a photo on the cloud document. The caller decides what to do with
/// the bytes — typically, [BirthdayPhotoService.decodeFromCloud] the
/// Base64 and write back into the local `avatarBase64` field.
class CloudPhotoFields {
  const CloudPhotoFields({
    required this.base64,
    required this.mimeType,
    required this.byteSize,
    required this.hash,
    required this.updatedAt,
  });

  final String base64;
  final String mimeType;
  final int byteSize;
  final String hash;
  final DateTime updatedAt;
}

/// Pair of (domain model, optional cloud photo) returned by
/// [BirthdayFirestoreMapper.fromFirestore].
class FirestoreBirthdayRecord {
  const FirestoreBirthdayRecord({required this.birthday, this.photo});
  final Birthday birthday;
  final CloudPhotoFields? photo;
}

/// Bidirectional converter between the on-disk [Birthday] model and the
/// canonical Firestore document under `/users/{uid}/birthdays/{id}`.
///
/// Photo handling:
///   * The local model keeps `avatarBase64` (Base64 of the
///     compressed JPEG). Sync never re-encodes from a local file.
///   * The cloud document stores `photoBase64`, `photoMimeType`,
///     `photoByteSize`, `photoHash` and `photoUpdatedAt`.
///   * Missing photo fields in the cloud are NOT interpreted as a
///     deletion: the sync layer must compare local vs cloud and
///     backfill instead of clearing.
class BirthdayFirestoreMapper {
  const BirthdayFirestoreMapper();

  /// Cloud schema version — bump only when a destructive migration is
  /// required. Rules validate this field.
  static const int schemaVersion = 1;

  /// Build the canonical Firestore map for an upsert. When [photo]
  /// is non-null the cloud fields are included; when it is null, the
  /// photo fields are explicitly removed via [FieldValue.delete] so
  /// the next sync reflects an intentional delete.
  Map<String, dynamic> toFirestore(
    Birthday b, {
    BirthdayCloudPhoto? photo,
    bool deletePhoto = false,
  }) {
    final map = <String, dynamic>{
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
      'isDeleted': b.deletedAt != null,
      'deletedAt':
          b.deletedAt == null ? null : Timestamp.fromDate(b.deletedAt!),
      'schemaVersion': schemaVersion,
    };

    if (photo != null) {
      map['photoBase64'] = photo.photoBase64;
      map['photoMimeType'] = photo.mimeType;
      map['photoByteSize'] = photo.byteSize;
      map['photoHash'] = photo.hash;
      map['photoUpdatedAt'] = Timestamp.fromDate(photo.updatedAt);
    } else if (deletePhoto) {
      map['photoBase64'] = FieldValue.delete();
      map['photoMimeType'] = FieldValue.delete();
      map['photoByteSize'] = FieldValue.delete();
      map['photoHash'] = FieldValue.delete();
      map['photoUpdatedAt'] = FieldValue.delete();
    }
    return map;
  }

  /// Build a [FirestoreBirthdayRecord] from a Firestore snapshot. The
  /// `birthday` is non-null when the document has the minimum viable
  /// fields (id + name). `photo` is null when no photo fields exist.
  FirestoreBirthdayRecord? fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
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

    final birthday = Birthday(
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

    final base64 = raw['photoBase64'] as String?;
    if (base64 == null || base64.isEmpty) {
      return FirestoreBirthdayRecord(birthday: birthday);
    }
    return FirestoreBirthdayRecord(
      birthday: birthday,
      photo: CloudPhotoFields(
        base64: base64,
        mimeType: raw['photoMimeType'] as String? ?? 'image/jpeg',
        byteSize: (raw['photoByteSize'] as num?)?.toInt() ?? 0,
        hash: raw['photoHash'] as String? ?? '',
        updatedAt:
            (raw['photoUpdatedAt'] as Timestamp?)?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );
  }
}
