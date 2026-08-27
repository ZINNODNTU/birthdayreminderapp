/// Centralised names for SQLite schema elements. Import this instead of
/// hard-coding strings in services and tests.
class DbSchema {
  const DbSchema._();

  static const String databaseFileName = 'birthdays.db';
  static const int databaseVersion = 2;

  static const String birthdaysTable = 'birthdays';

  // Column names. Keep in sync with the v2 onCreate body.
  static const String colId = 'id';
  static const String colName = 'name';
  static const String colAvatarBase64 = 'avatarBase64';
  static const String colGender = 'gender';
  static const String colNickname = 'nickname';
  static const String colRelationship = 'relationship';
  static const String colSolarBirthday = 'solarBirthday';
  static const String colLunarDay = 'lunarDay';
  static const String colLunarMonth = 'lunarMonth';
  static const String colLunarYear = 'lunarYear';
  static const String colCalendarType = 'calendarType';
  static const String colRemindBeforeDays = 'remindBeforeDays';
  static const String colRemindTime = 'remindTime';
  static const String colIsRecurringNotificationEnabled =
      'isRecurringNotificationEnabled';
  static const String colRepeatAnnually = 'repeatAnnually';
  static const String colNote = 'note';
  // v2 metadata
  static const String colCreatedAt = 'created_at';
  static const String colUpdatedAt = 'updated_at';
  static const String colDeletedAt = 'deleted_at';
  static const String colSyncStatus = 'sync_status';
  static const String colOwnerUid = 'owner_uid';
  static const String colSchemaVersion = 'schema_version';

  /// Bumped on the `Birthday` JSON shape (separate from SQLite schema).
  static const int birthdaySchemaVersion = 2;
}
