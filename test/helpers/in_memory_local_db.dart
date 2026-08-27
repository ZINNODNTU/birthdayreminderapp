import 'dart:io';

import 'package:birthdayreminderapp/services/local_db_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:birthdayreminderapp/core/db/db_schema.dart';

/// Test helper that exposes a temp-file SQLite database already opened at
/// the latest schema version. Use [create] in `setUp`.
class InMemoryLocalDb {
  InMemoryLocalDb._(this.service, this._db, this._path);

  final LocalDbService service;
  final Database _db;
  final String _path;

  Future<void> close() async {
    await _db.close();
    final file = File(_path);
    if (await file.exists()) await file.delete();
  }

  static int _counter = 0;

  static Future<InMemoryLocalDb> create() async {
    final dir = Directory.systemTemp.createTempSync('br_test_db_');
    final path = '${dir.path}/db_${++_counter}.sqlite';
    final db = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: DbSchema.databaseVersion,
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
      ),
    );
    return InMemoryLocalDb._(LocalDbService(testDatabase: db), db, path);
  }
}

void initSqfliteFfi() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
