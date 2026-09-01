import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/firestore/firestore_schema.dart';
import '../../../models/birthday.dart';
import '../services/birthday_photo_service.dart';

/// Cloud-side photo payload extracted from a [Birthday]. Always built
/// at the moment of an upsert so the encoded bytes never outlive a
/// single sync cycle.
class BirthdayCloudPhoto {
  const BirthdayCloudPhoto({
    required this.photoBase64,
    required this.mimeType,
    required this.size,
    required this.hash,
    required this.updatedAt,
  });

  final String photoBase64;
  final String mimeType;
  final int size;
  final String hash;
  final DateTime updatedAt;

  BirthdayCloudPhoto.fromEncoded(EncodedBirthdayPhoto e, {DateTime? now})
    : photoBase64 = e.base64,
      mimeType = e.mimeType,
      size = e.byteSize,
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
    required this.size,
    required this.hash,
    required this.updatedAt,
  });

  final String base64;
  final String mimeType;
  final int size;
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
  static const int schemaVersion = FirestoreSchema.version;

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
      'name': b.name.trim().isEmpty ? 'Không có tên' : b.name.trim(),
      'birthdayDate': Timestamp.fromDate(b.solarBirthday),
      'calendarType': b.calendarType.name,
      if (b.relationship != null) 'relationship': b.relationship,
      if (b.gender != null) 'gender': b.gender,
      'note': b.note,
      'remindBeforeDays': b.remindBeforeDays,
      'reminderEnabled': b.isRecurringNotificationEnabled,
      'reminderTime':
          '${b.remindTime.hour.toString().padLeft(2, '0')}:'
          '${b.remindTime.minute.toString().padLeft(2, '0')}',
      'repeatYearly': b.repeatAnnually,
      'createdAt': b.createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(b.createdAt!),
      'updatedAt': Timestamp.fromDate(b.updatedAt ?? DateTime.now()),
      'schemaVersion': schemaVersion,
    };

    if (photo != null) {
      map['photoBase64'] = photo.photoBase64;
      map['photoMimeType'] = photo.mimeType;
      map['photoSize'] = photo.size;
      map['photoHash'] = photo.hash;
      map['photoUpdatedAt'] = Timestamp.fromDate(photo.updatedAt);
    } else if (deletePhoto) {
      map['photoBase64'] = FieldValue.delete();
      map['photoMimeType'] = FieldValue.delete();
      map['photoSize'] = FieldValue.delete();
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

    final solar =
        _date(raw['birthdayDate'] ?? raw['solarBirthday']) ??
        DateTime(2000, 1, 1);

    final lunarMap = raw['lunar'] as Map<String, dynamic>?;
    final lunar = LunarDateTime(
      day: _integer(lunarMap?['day'] ?? raw['lunarDay'], fallback: 1),
      month: _integer(lunarMap?['month'] ?? raw['lunarMonth'], fallback: 1),
      year: _integer(lunarMap?['year'] ?? raw['lunarYear'], fallback: 2000),
    );

    final reminder = raw['reminder'] as Map<String, dynamic>?;
    final legacyTime = (raw['reminderTime'] ?? raw['remindTime'])
        ?.toString()
        .split(':');
    final hour = _integer(
      reminder?['hour'] ??
          (legacyTime?.isNotEmpty == true ? legacyTime!.first : null),
      fallback: 9,
    );
    final minute = _integer(
      reminder?['minute'] ??
          (legacyTime != null && legacyTime.length > 1 ? legacyTime[1] : null),
    );
    final clampedHour = hour.clamp(0, 23);
    final clampedMinute = minute.clamp(0, 59);
    final daysBefore = _integer(
      raw['remindBeforeDays'] ?? reminder?['daysBefore'],
    );

    final birthday = Birthday(
      id: id,
      name: name,
      solarBirthday: solar,
      lunarBirthday: lunar,
      calendarType: calendarType,
      remindBeforeDays: daysBefore,
      remindTime: TimeOfDay(hour: clampedHour, minute: clampedMinute),
      isRecurringNotificationEnabled: _boolean(
        raw['reminderEnabled'] ??
            reminder?['enabled'] ??
            raw['isRecurringNotificationEnabled'],
      ),
      repeatAnnually: _boolean(
        raw['repeatYearly'] ??
            reminder?['repeatAnnually'] ??
            raw['repeatAnnually'],
      ),
      nickname: raw['nickname'] as String?,
      gender: raw['gender'] as String?,
      relationship: raw['relationship'] as String?,
      note: raw['note'] as String?,
      createdAt: _date(raw['createdAt'] ?? raw['created_at']),
      updatedAt: _date(raw['updatedAt'] ?? raw['updated_at']),
      deletedAt: _date(raw['deletedAt'] ?? raw['deleted_at']),
      schemaVersion: _integer(
        raw['schemaVersion'] ?? raw['schema_version'],
        fallback: 1,
      ),
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
        size: _integer(raw['photoSize'] ?? raw['photoByteSize']),
        hash: raw['photoHash'] as String? ?? '',
        updatedAt:
            _date(raw['photoUpdatedAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );
  }

  static DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static int _integer(Object? value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static bool _boolean(Object? value) =>
      value == true || value == 1 || value == '1' || value == 'true';
}
