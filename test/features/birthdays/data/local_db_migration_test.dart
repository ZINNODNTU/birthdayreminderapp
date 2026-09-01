import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:birthdayreminderapp/core/db/db_schema.dart';
import 'package:birthdayreminderapp/core/db/sync_status.dart';
import 'package:birthdayreminderapp/services/local_db_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('fresh v3 DB has indexes', () async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: DbSchema.databaseVersion,
      onCreate: (db, version) {
        return LocalDbService().onCreate(db, version);
      },
    );
    final indexList = await db.rawQuery(
      'PRAGMA index_list(${DbSchema.birthdaysTable})',
    );
    final indexNames = indexList.map((row) => row['name'] as String).toList();
    expect(indexNames, contains('idx_birthdays_deleted_updated'));
  });

  test('v2 → v3 migration preserves rows and adds indexes', () async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE ${DbSchema.birthdaysTable} (
            ${DbSchema.colId} TEXT PRIMARY KEY,
            ${DbSchema.colName} TEXT,
            ${DbSchema.colAvatarBase64} TEXT,
            ${DbSchema.colGender} TEXT,
            ${DbSchema.colNickname} TEXT,
            ${DbSchema.colRelationship} TEXT,
            ${DbSchema.colSolarBirthday} TEXT,
            ${DbSchema.colLunarDay} INTEGER,
            ${DbSchema.colLunarMonth} INTEGER,
            ${DbSchema.colLunarYear} INTEGER,
            ${DbSchema.colCalendarType} TEXT,
            ${DbSchema.colRemindBeforeDays} INTEGER,
            ${DbSchema.colRemindTime} TEXT,
            ${DbSchema.colIsRecurringNotificationEnabled} INTEGER,
            ${DbSchema.colRepeatAnnually} INTEGER,
            ${DbSchema.colNote} TEXT,
            ${DbSchema.colCreatedAt} TEXT,
            ${DbSchema.colUpdatedAt} TEXT,
            ${DbSchema.colDeletedAt} TEXT,
            ${DbSchema.colSyncStatus} TEXT,
            ${DbSchema.colOwnerUid} TEXT,
            ${DbSchema.colSchemaVersion} INTEGER
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) {
        return LocalDbService().migrate(db, oldVersion, newVersion);
      },
    );

    // Insert rows after opening to ensure they exist
    await db.insert(DbSchema.birthdaysTable, {
      DbSchema.colId: 'test-1',
      DbSchema.colName: 'Alice',
      DbSchema.colAvatarBase64: null,
      DbSchema.colGender: 'female',
      DbSchema.colNickname: 'Ali',
      DbSchema.colRelationship: 'friend',
      DbSchema.colSolarBirthday: '2000-01-01T00:00:00.000',
      DbSchema.colLunarDay: 1,
      DbSchema.colLunarMonth: 1,
      DbSchema.colLunarYear: 2000,
      DbSchema.colCalendarType: 'CalendarType.solar',
      DbSchema.colRemindBeforeDays: 1,
      DbSchema.colRemindTime: '09:00',
      DbSchema.colIsRecurringNotificationEnabled: 1,
      DbSchema.colRepeatAnnually: 1,
      DbSchema.colNote: null,
      DbSchema.colCreatedAt: '2025-01-01T00:00:00.000',
      DbSchema.colUpdatedAt: '2025-01-02T00:00:00.000',
      DbSchema.colDeletedAt: null,
      DbSchema.colSyncStatus: SyncStatus.synced.storageValue,
      DbSchema.colOwnerUid: 'user-1',
      DbSchema.colSchemaVersion: 2,
    });
    await db.insert(DbSchema.birthdaysTable, {
      DbSchema.colId: 'test-2-deleted',
      DbSchema.colName: 'Bob',
      DbSchema.colAvatarBase64: null,
      DbSchema.colGender: 'male',
      DbSchema.colNickname: null,
      DbSchema.colRelationship: 'colleague',
      DbSchema.colSolarBirthday: '1990-05-15T00:00:00.000',
      DbSchema.colLunarDay: 15,
      DbSchema.colLunarMonth: 5,
      DbSchema.colLunarYear: 1990,
      DbSchema.colCalendarType: 'CalendarType.lunar',
      DbSchema.colRemindBeforeDays: 0,
      DbSchema.colRemindTime: '12:00',
      DbSchema.colIsRecurringNotificationEnabled: 0,
      DbSchema.colRepeatAnnually: 0,
      DbSchema.colNote: null,
      DbSchema.colCreatedAt: '2025-06-01T00:00:00.000',
      DbSchema.colUpdatedAt: '2025-06-02T00:00:00.000',
      DbSchema.colDeletedAt: '2025-06-03T00:00:00.000',
      DbSchema.colSyncStatus: SyncStatus.pendingDelete.storageValue,
      DbSchema.colOwnerUid: 'user-2',
      DbSchema.colSchemaVersion: 2,
    });

    // Verify rows exist before migration
    final preRows = await db.query(DbSchema.birthdaysTable);
    expect(preRows.length, 2);

    // Upgrade to v3
    await LocalDbService().migrate(db, 2, 3);

    // Verify indexes exist
    final postUpgradeIndexList = await db.rawQuery(
      'PRAGMA index_list(${DbSchema.birthdaysTable})',
    );
    final postUpgradeIndexNames = postUpgradeIndexList
        .map((row) => row['name'] as String)
        .toList();
    expect(postUpgradeIndexNames, contains('idx_birthdays_deleted_updated'));
  });
}
