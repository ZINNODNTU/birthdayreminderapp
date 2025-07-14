import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/birthday.dart';

class LocalDBService {
  static final LocalDBService _instance = LocalDBService._internal();
  factory LocalDBService() => _instance;

  LocalDBService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'birthdays.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE birthdays (
            id TEXT PRIMARY KEY,
            name TEXT,
            avatarBase64 TEXT,
            gender TEXT,
            nickname TEXT,
            relationship TEXT,
            solarBirthday TEXT,
            lunarDay INTEGER,
            lunarMonth INTEGER,
            lunarYear INTEGER,
            calendarType TEXT,
            remindBeforeDays INTEGER,
            remindTime TEXT,
            isRecurringNotificationEnabled INTEGER,
            repeatAnnually INTEGER,
            note TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertBirthday(Birthday birthday) async {
    final db = await database;
    await db.insert(
      'birthdays',
      {
        'id': birthday.id,
        'name': birthday.name,
        'avatarBase64': birthday.avatarBase64,
        'gender': birthday.gender,
        'nickname': birthday.nickname,
        'relationship': birthday.relationship,
        'solarBirthday': birthday.solarBirthday.toIso8601String(),
        'lunarDay': birthday.lunarBirthday.day,
        'lunarMonth': birthday.lunarBirthday.month,
        'lunarYear': birthday.lunarBirthday.year,
        'calendarType': birthday.calendarType.toString(),
        'remindBeforeDays': birthday.remindBeforeDays,
        'remindTime': '${birthday.remindTime.hour}:${birthday.remindTime.minute}',
        'isRecurringNotificationEnabled': birthday.isRecurringNotificationEnabled ? 1 : 0,
        'repeatAnnually': birthday.repeatAnnually ? 1 : 0,
        'note': birthday.note,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Birthday>> getBirthdays() async {
    final db = await database;
    final maps = await db.query('birthdays');
    return List.generate(maps.length, (i) => Birthday.fromMap(maps[i]));
  }

  Future<void> updateBirthday(Birthday birthday) async {
    final db = await database;
    await db.update(
      'birthdays',
      {
        'id': birthday.id,
        'name': birthday.name,
        'avatarBase64': birthday.avatarBase64,
        'gender': birthday.gender,
        'nickname': birthday.nickname,
        'relationship': birthday.relationship,
        'solarBirthday': birthday.solarBirthday.toIso8601String(),
        'lunarDay': birthday.lunarBirthday.day,
        'lunarMonth': birthday.lunarBirthday.month,
        'lunarYear': birthday.lunarBirthday.year,
        'calendarType': birthday.calendarType.toString(),
        'remindBeforeDays': birthday.remindBeforeDays,
        'remindTime': '${birthday.remindTime.hour}:${birthday.remindTime.minute}',
        'isRecurringNotificationEnabled': birthday.isRecurringNotificationEnabled ? 1 : 0,
        'repeatAnnually': birthday.repeatAnnually ? 1 : 0,
        'note': birthday.note,
      },
      where: 'id = ?',
      whereArgs: [birthday.id],
    );
  }

  Future<void> deleteBirthday(String id) async {
    final db = await database;
    await db.delete('birthdays', where: 'id = ?', whereArgs: [id]);
  }
}