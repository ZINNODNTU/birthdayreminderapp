import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:birthdayreminderapp/core/db/sync_status.dart';
import 'package:birthdayreminderapp/features/backup/domain/backup_models.dart';
import 'package:birthdayreminderapp/features/backup/services/backup_service.dart';
import 'package:birthdayreminderapp/features/birthdays/data/birthday_repository.dart';
import 'package:birthdayreminderapp/models/birthday.dart';

class MemoryRepo implements BirthdayRepository {
  MemoryRepo([List<Birthday> rows = const []])
    : data = {for (final b in rows) b.id: b};
  final Map<String, Birthday> data;
  @override
  Future<void> createBirthday(Birthday b) async => data[b.id] = b;
  @override
  Future<void> updateBirthday(Birthday b) async => data[b.id] = b;
  @override
  Future<void> upsertBirthday(Birthday b) async => data[b.id] = b;
  @override
  Future<void> deleteBirthday(String id) async => data.remove(id);
  @override
  Future<Birthday?> getBirthday(String id) async => data[id];
  @override
  Future<List<Birthday>> getBirthdays() async =>
      data.values.where((b) => b.deletedAt == null).toList();
  @override
  Future<List<Birthday>> getAllForSync() async => data.values.toList();
  @override
  Stream<List<Birthday>> watchBirthdays() async* {
    yield await getBirthdays();
  }
}

Birthday sample({
  String id = 'a',
  DateTime? updated,
  String? photo,
  DateTime? deleted,
}) => Birthday(
  id: id,
  name: 'An',
  nickname: 'Bi',
  gender: 'Nam',
  relationship: 'Bạn',
  solarBirthday: DateTime(2000, 2, 29),
  lunarBirthday: LunarDateTime(day: 1, month: 2, year: 2000),
  calendarType: CalendarType.solar,
  remindBeforeDays: 3,
  remindTime: const TimeOfDay(hour: 8, minute: 30),
  isRecurringNotificationEnabled: true,
  repeatAnnually: true,
  note: 'Ghi chú',
  avatarBase64: photo,
  createdAt: DateTime.utc(2020),
  updatedAt: updated ?? DateTime.utc(2024),
  deletedAt: deleted,
  syncStatus: SyncStatus.pendingUpload,
  ownerUid: 'owner',
  schemaVersion: 2,
);
void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'theme_mode': 'dark',
      'ai_config': 'SECRET_TOKEN',
      'app_update_last_check': 123,
    }),
  );
  test(
    'full round trip preserves user data photo tombstone and portable settings',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final photo = base64Encode([1, 2, 3, 4]);
      final source = MemoryRepo([
        sample(photo: photo),
        sample(id: 'dead', deleted: DateTime.utc(2025)),
      ]);
      final result =
          await BackupService(
            repository: source,
            preferences: prefs,
            packageInfo: PackageInfo(
              appName: 'x',
              packageName: 'x',
              version: '1.0.1',
              buildNumber: '2',
            ),
          ).createBackup();
      expect(result.birthdayCount, 2);
      expect(result.photoCount, 1);
      final text = utf8.decode(result.bytes, allowMalformed: true);
      expect(text, contains('manifest.json'));
      expect(text, isNot(contains('SECRET_TOKEN')));
      final plan = await RestoreService.validateBytes(result.bytes);
      expect(plan.records.length, 2);
      expect(plan.records.first.avatarBase64, photo);
      expect(plan.records.first.ownerUid, isNull);
      expect(plan.records.first.syncStatus, SyncStatus.localOnly);
      expect(
        plan.records.singleWhere((b) => b.id == 'dead').deletedAt,
        isNotNull,
      );
      final target = MemoryRepo();
      final restored = await RestoreService(
        repository: target,
        preferences: prefs,
      ).apply(plan);
      expect(restored.restored, 2);
      expect(target.data['a']!.solarBirthday, DateTime(2000, 2, 29));
      expect(target.data['a']!.note, 'Ghi chú');
      expect(target.data['a']!.remindBeforeDays, 3);
    },
  );
  test('bad zip rejected before mutation', () async {
    expect(
      () => RestoreService.validateBytes(Uint8List.fromList([1, 2, 3])),
      throwsFormatException,
    );
  });

  test('legacy remindBeforeDays missing and numeric string are safe', () {
    Map<String, dynamic> legacy(Object? days) => {
      'id': 'legacy-$days',
      'name': 'Legacy',
      'solarBirthday': '2000-01-01T00:00:00.000',
      'lunarDay': 1,
      'lunarMonth': 1,
      'lunarYear': 2000,
      'calendarType': 'solar',
      if (days != null) 'remindBeforeDays': days,
      'remindHour': 8,
      'remindMinute': 0,
      'notificationEnabled': true,
      'repeatAnnually': true,
      'syncStatus': 'localOnly',
      'schemaVersion': 1,
    };

    expect(birthdayFromBackupJson(legacy(null)).remindBeforeDays, 0);
    expect(birthdayFromBackupJson(legacy('2')).remindBeforeDays, 2);
    expect(birthdayFromBackupJson(legacy('bad')).remindBeforeDays, 0);
  });
  test('future schema rejected', () async {
    final prefs = await SharedPreferences.getInstance();
    final bytes =
        (await BackupService(
              repository: MemoryRepo(),
              preferences: prefs,
              packageInfo: PackageInfo(
                appName: 'x',
                packageName: 'x',
                version: '1',
                buildNumber: '1',
              ),
            ).createBackup())
            .bytes;
    final decoded = ZipDecoder().decodeBytes(bytes);
    final manifest = decoded.findFile('manifest.json')!;
    final json =
        jsonDecode(utf8.decode(manifest.content as List<int>))
            as Map<String, dynamic>;
    json['schemaVersion'] = 999;
    final changed = utf8.encode(jsonEncode(json));
    final changedArchive = Archive();
    for (final file in decoded) {
      if (file.name != 'manifest.json') changedArchive.addFile(file);
    }
    changedArchive.addFile(
      ArchiveFile('manifest.json', changed.length, changed),
    );
    expect(
      () => RestoreService.validateBytes(
        Uint8List.fromList(ZipEncoder().encode(changedArchive)),
      ),
      throwsFormatException,
    );
  });
  test('merge keeps local newer and accepts backup newer', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = MemoryRepo([
      sample(updated: DateTime.utc(2025)),
      sample(id: 'b', updated: DateTime.utc(2020)),
    ]);
    final plan = RestorePlan(
      createdAt: DateTime.now(),
      appVersion: '1',
      records: [
        sample(updated: DateTime.utc(2024)),
        sample(id: 'b', updated: DateTime.utc(2026)),
      ],
      settings: const {},
      photos: const {},
      warnings: const [],
    );
    final r = await RestoreService(
      repository: repo,
      preferences: prefs,
    ).apply(plan);
    expect(r.skipped, 1);
    expect(r.restored, 1);
    expect(repo.data['b']!.updatedAt, DateTime.utc(2026));
  });
}
