import 'package:flutter/material.dart';

import '../../../core/db/sync_status.dart';
import '../../../models/birthday.dart';
import '../../../services/local_db_service.dart';
import 'birthday_repository.dart';

/// SQLite-backed [BirthdayRepository]. Used in both local and authenticated
/// modes; ownership / cloud sync is handled by higher layers.
class LocalBirthdayRepository implements BirthdayRepository {
  LocalBirthdayRepository(this._db);

  final LocalDbService _db;

  @override
  Future<List<Birthday>> getBirthdays() => _db.getBirthdays();

  @override
  Future<Birthday?> getBirthday(String id) => _db.getBirthday(id);

  @override
  Future<void> createBirthday(Birthday birthday) async {
    final now = DateTime.now();
    final stamped = birthday.copyWith(
      createdAt: birthday.createdAt ?? now,
      updatedAt: now,
      syncStatus:
          birthday.ownerUid == null
              ? SyncStatus.localOnly
              : SyncStatus.pendingUpload,
    );
    await _db.insertBirthday(stamped);
  }

  @override
  Future<void> updateBirthday(Birthday birthday) async {
    final stamped = birthday.copyWith(updatedAt: DateTime.now());
    await _db.updateBirthday(stamped);
  }

  @override
  Future<void> deleteBirthday(String id) => _db.deleteBirthday(id);

  @override
  Stream<List<Birthday>> watchBirthdays() async* {
    yield await _db.getBirthdays();
  }
}

extension BirthdayCopy on Birthday {
  Birthday copyWith({
    String? id,
    String? name,
    String? avatarBase64,
    String? gender,
    String? nickname,
    String? relationship,
    DateTime? solarBirthday,
    LunarDateTime? lunarBirthday,
    CalendarType? calendarType,
    int? remindBeforeDays,
    TimeOfDay? remindTime,
    bool? isRecurringNotificationEnabled,
    bool? repeatAnnually,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    SyncStatus? syncStatus,
    String? ownerUid,
    int? schemaVersion,
  }) {
    return Birthday(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarBase64: avatarBase64 ?? this.avatarBase64,
      gender: gender ?? this.gender,
      nickname: nickname ?? this.nickname,
      relationship: relationship ?? this.relationship,
      solarBirthday: solarBirthday ?? this.solarBirthday,
      lunarBirthday: lunarBirthday ?? this.lunarBirthday,
      calendarType: calendarType ?? this.calendarType,
      remindBeforeDays: remindBeforeDays ?? this.remindBeforeDays,
      remindTime: remindTime ?? this.remindTime,
      isRecurringNotificationEnabled:
          isRecurringNotificationEnabled ?? this.isRecurringNotificationEnabled,
      repeatAnnually: repeatAnnually ?? this.repeatAnnually,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      ownerUid: ownerUid ?? this.ownerUid,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }
}
