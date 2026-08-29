import '../../../core/db/sync_status.dart';
import '../../../models/birthday.dart';

/// Sync-only mutation surface. We deliberately do NOT extend
/// `Birthday.copyWith` because production logic must not be able to
/// overwrite `id`, `name`, `createdAt`, or any other identity field
/// after sync stamps it.
extension BirthdaySyncCopy on Birthday {
  Birthday copyWithForSync({
    SyncStatus? syncStatus,
    String? ownerUid,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Birthday(
      id: id,
      name: name,
      avatarBase64: avatarBase64,
      gender: gender,
      nickname: nickname,
      relationship: relationship,
      solarBirthday: solarBirthday,
      lunarBirthday: lunarBirthday,
      calendarType: calendarType,
      remindBeforeDays: remindBeforeDays,
      remindTime: remindTime,
      isRecurringNotificationEnabled: isRecurringNotificationEnabled,
      repeatAnnually: repeatAnnually,
      note: note,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      ownerUid: ownerUid ?? this.ownerUid,
      schemaVersion: schemaVersion,
    );
  }
}
