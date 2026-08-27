import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../core/db/db_schema.dart';
import '../core/db/sync_status.dart';
import '../core/logging/app_logger.dart';
import '../models/birthday.dart';

/// Wraps the local SQLite database. The schema is versioned and migrations
/// live in [_migrate]; fresh installs jump straight to the latest schema in
/// [onCreate].
class LocalDbService {
  LocalDbService({Database? testDatabase}) : _testDatabase = testDatabase;

  final Database? _testDatabase;
  Database? _database;

  Future<Database> get database async {
    if (_testDatabase != null) return _testDatabase;
    return _database ??= await _initDB();
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), DbSchema.databaseFileName);
    return openDatabase(
      path,
      version: DbSchema.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _migrate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
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
  }

  Future<void> _migrate(Database db, int oldVersion, int newVersion) async {
    AppLogger.info('LocalDbService', 'migrating v$oldVersion → v$newVersion');
    if (oldVersion < 2) {
      await _v1ToV2(db);
    }
    // Future migrations chain here.
  }

  /// v1 → v2: add sync-ready metadata columns. Existing rows have no real
  /// timestamps; we backfill them with the migration time so they have a
  /// non-null value to read. Schema version is bumped to 2.
  Future<void> _v1ToV2(Database db) async {
    final migrationTime = DateTime.now().toIso8601String();
    const cols = <String, String>{
      DbSchema.colCreatedAt: 'TEXT',
      DbSchema.colUpdatedAt: 'TEXT',
      DbSchema.colDeletedAt: 'TEXT',
      DbSchema.colSyncStatus: 'TEXT',
      DbSchema.colOwnerUid: 'TEXT',
      DbSchema.colSchemaVersion: 'INTEGER',
    };
    for (final entry in cols.entries) {
      await db.execute(
        'ALTER TABLE ${DbSchema.birthdaysTable} ADD COLUMN ${entry.key} ${entry.value}',
      );
    }
    // Default values for existing rows.
    await db.execute(
      'UPDATE ${DbSchema.birthdaysTable} SET '
      '${DbSchema.colCreatedAt} = ?, ${DbSchema.colUpdatedAt} = ?, '
      '${DbSchema.colSyncStatus} = ?, ${DbSchema.colSchemaVersion} = ?',
      [migrationTime, migrationTime, SyncStatus.localOnly.storageValue, 2],
    );
  }

  Future<void> insertBirthday(Birthday birthday) async {
    final db = await database;
    await db.insert(
      DbSchema.birthdaysTable,
      birthday.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Birthday>> getBirthdays({bool includeDeleted = false}) async {
    final db = await database;
    final maps = await db.query(
      DbSchema.birthdaysTable,
      where: includeDeleted ? null : '${DbSchema.colDeletedAt} IS NULL',
      orderBy: '${DbSchema.colUpdatedAt} DESC',
    );
    return List.generate(maps.length, (i) => Birthday.fromDbMap(maps[i]));
  }

  Future<Birthday?> getBirthday(String id) async {
    final db = await database;
    final rows = await db.query(
      DbSchema.birthdaysTable,
      where: '${DbSchema.colId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Birthday.fromDbMap(rows.first);
  }

  Future<void> updateBirthday(Birthday birthday) async {
    final db = await database;
    await db.update(
      DbSchema.birthdaysTable,
      birthday.toDbMap(),
      where: '${DbSchema.colId} = ?',
      whereArgs: [birthday.id],
    );
  }

  Future<void> deleteBirthday(String id) async {
    final db = await database;
    await db.delete(
      DbSchema.birthdaysTable,
      where: '${DbSchema.colId} = ?',
      whereArgs: [id],
    );
  }
}
