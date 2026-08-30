// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/db/db_schema.dart';
import '../../../core/logging/app_logger.dart';
import '../../../models/birthday.dart';
import '../../birthdays/data/birthday_repository.dart';
import '../domain/backup_models.dart';
import 'backup_file_service.dart';

class BackupService {
  BackupService({
    required BirthdayRepository repository,
    required SharedPreferences preferences,
    PackageInfo? packageInfo,
  }) : _repository = repository,
       _preferences = preferences,
       _packageInfo = packageInfo;
  final BirthdayRepository _repository;
  final SharedPreferences _preferences;
  final PackageInfo? _packageInfo;
  static const portableSettings = <String>{
    'theme_mode',
    'locale',
    'default_remind_before_days',
    'default_remind_hour',
    'default_remind_minute',
  };

  Future<BackupResult> createBackup() async {
    final rows = await _repository.getAllForSync();
    if (rows.length > maxBirthdays)
      throw const FormatException('Too many birthdays');
    final archive = Archive();
    final warnings = <RestoreWarning>[];
    final records = <Map<String, Object?>>[];
    final files = <Map<String, Object?>>[];
    var photos = 0;
    void add(String path, List<int> bytes) {
      archive.addFile(ArchiveFile(path, bytes.length, bytes));
      files.add({'path': path, 'sha256': sha256.convert(bytes).toString()});
    }

    for (final b in rows) {
      String? photoFile, hash;
      int? size;
      if (b.avatarBase64?.isNotEmpty == true) {
        final clean = BackupFileService.normalizeBase64(b.avatarBase64!);
        if (clean == null) {
          warnings.add(
            RestoreWarning('corrupt_photo', 'Bỏ qua ảnh lỗi của ${b.name}'),
          );
        } else {
          try {
            final bytes = base64Decode(clean);
            if (bytes.length > maxPhotoBytes)
              throw const FormatException('photo too large');
            photoFile = 'photos/${b.id}.jpg';
            hash = sha256.convert(bytes).toString();
            size = bytes.length;
            add(photoFile, bytes);
            photos++;
          } catch (e) {
            AppLogger.warn('BackupService', 'photo skipped for ${b.id}: $e');
            warnings.add(
              RestoreWarning('corrupt_photo', 'Bỏ qua ảnh lỗi của ${b.name}'),
            );
          }
        }
      }
      records.add(
        birthdayToBackupJson(
          b,
          photoFile: photoFile,
          photoHash: hash,
          photoSize: size,
        ),
      );
    }
    final birthdays = utf8.encode(jsonEncode({'records': records}));
    add('birthdays.json', birthdays);
    final settings = <String, Object?>{};
    for (final key in portableSettings) {
      final value = _preferences.get(key);
      if (value is String || value is bool || value is int || value is double)
        settings[key] = value;
    }
    final settingsBytes = utf8.encode(jsonEncode(settings));
    add('settings.json', settingsBytes);
    final info = _packageInfo ?? await PackageInfo.fromPlatform();
    final now = DateTime.now().toUtc();
    final manifest = utf8.encode(
      jsonEncode({
        'format': backupFormat,
        'schemaVersion': backupSchemaVersion,
        'backupType': 'birthday_reminder_full',
        'createdAt': now.toIso8601String(),
        'appVersion': info.version,
        'buildNumber': int.tryParse(info.buildNumber) ?? 0,
        'databaseVersion': DbSchema.databaseVersion,
        'birthdaySchemaVersion': DbSchema.birthdaySchemaVersion,
        'birthdayCount': rows.length,
        'photoCount': photos,
        'files': files,
      }),
    );
    archive.addFile(ArchiveFile('manifest.json', manifest.length, manifest));
    final encoded = ZipEncoder().encode(archive);
    if (encoded.length > maxBackupBytes)
      throw const FormatException('Backup too large');
    final bytes = Uint8List.fromList(encoded);
    await RestoreService.validateBytes(bytes);
    String two(int n) => n.toString().padLeft(2, '0');
    final name =
        'BirthdayReminder-Backup-${now.year}${two(now.month)}${two(now.day)}-${two(now.hour)}${two(now.minute)}${two(now.second)}.zip';
    return BackupResult(
      bytes: bytes,
      fileName: name,
      birthdayCount: rows.length,
      photoCount: photos,
      warnings: warnings,
    );
  }
}

class RestoreService {
  RestoreService({
    required BirthdayRepository repository,
    required SharedPreferences preferences,
  }) : _repository = repository,
       _preferences = preferences;
  final BirthdayRepository _repository;
  final SharedPreferences _preferences;

  static Future<RestorePlan> validateBytes(
    Uint8List bytes, {
    RestoreMode mode = RestoreMode.signingMigration,
  }) async {
    if (bytes.length > maxBackupBytes)
      throw const FormatException('Archive too large');
    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes, verify: true);
    } catch (_) {
      throw const FormatException('Invalid ZIP');
    }
    if (archive.length > maxEntries)
      throw const FormatException('Too many entries');
    final map = <String, Uint8List>{};
    var expanded = 0;
    for (final f in archive) {
      final p = f.name.replaceAll('\\', '/');
      if (p.startsWith('/') ||
          RegExp(r'^[A-Za-z]:').hasMatch(p) ||
          p.split('/').contains('..'))
        throw const FormatException('Unsafe ZIP path');
      if (!f.isFile) continue;
      expanded += f.size;
      if (expanded > maxExpandedBytes)
        throw const FormatException('Expanded backup too large');
      map[p] = Uint8List.fromList(f.content as List<int>);
    }
    final manifestBytes = map['manifest.json'];
    if (manifestBytes == null) throw const FormatException('Missing manifest');
    if (manifestBytes.length > maxJsonBytes)
      throw const FormatException('Manifest too large');
    final manifest = jsonDecode(utf8.decode(manifestBytes));
    if (manifest is! Map<String, dynamic> ||
        manifest['schemaVersion'] is! int ||
        !supportedBackupSchemaVersions.contains(manifest['schemaVersion']) ||
        manifest['backupType'] != 'birthday_reminder_full' ||
        (manifest['schemaVersion'] == backupSchemaVersion &&
            manifest['format'] != backupFormat)) {
      throw const FormatException('Unsupported backup schema');
    }
    final files = manifest['files'];
    if (files is! List) throw const FormatException('Invalid checksums');
    for (final item in files) {
      if (item is! Map<String, dynamic>)
        throw const FormatException('Invalid checksum item');
      final p = item['path'];
      final expected = item['sha256'];
      final content = map[p];
      if (p is! String ||
          expected is! String ||
          content == null ||
          sha256.convert(content).toString() != expected)
        throw FormatException('Checksum mismatch: $p');
    }
    final birthdayBytes = map['birthdays.json'];
    final settingsBytes = map['settings.json'];
    if (birthdayBytes == null ||
        settingsBytes == null ||
        birthdayBytes.length > maxJsonBytes ||
        settingsBytes.length > maxJsonBytes)
      throw const FormatException('Missing/large JSON');
    final root = jsonDecode(utf8.decode(birthdayBytes));
    if (root is! Map<String, dynamic> || root['records'] is! List)
      throw const FormatException('Invalid birthdays JSON');
    final raw = root['records'] as List;
    if (raw.length > maxBirthdays)
      throw const FormatException('Too many birthdays');
    final ids = <String>{};
    final records = <Birthday>[];
    final photos = <String, Uint8List>{};
    final warnings = <RestoreWarning>[];
    for (final value in raw) {
      if (value is! Map<String, dynamic>)
        throw const FormatException('Invalid birthday');
      final id = value['id'];
      if (id is! String || id.isEmpty || !ids.add(id))
        throw const FormatException('Duplicate/invalid birthday ID');
      String? avatar;
      final path = value['photoBackupFile'];
      if (path != null) {
        if (path is! String || !path.startsWith('photos/'))
          throw const FormatException('Invalid photo path');
        final photo = map[path];
        final expected = value['photoHash'];
        if (photo == null ||
            photo.length > maxPhotoBytes ||
            expected is! String ||
            sha256.convert(photo).toString() != expected) {
          warnings.add(RestoreWarning('bad_photo', 'Bỏ qua ảnh lỗi của $id'));
        } else {
          avatar = base64Encode(photo);
          photos[id] = photo;
        }
      }
      records.add(
        birthdayFromBackupJson(value, avatarBase64: avatar, mode: mode),
      );
    }
    final settingsRaw = jsonDecode(utf8.decode(settingsBytes));
    if (settingsRaw is! Map<String, dynamic>)
      throw const FormatException('Invalid settings');
    final settings = <String, Object?>{};
    for (final e in settingsRaw.entries) {
      if (BackupService.portableSettings.contains(e.key) &&
          (e.value is String ||
              e.value is bool ||
              e.value is int ||
              e.value is double))
        settings[e.key] = e.value;
    }
    return RestorePlan(
      createdAt: DateTime.parse(manifest['createdAt'] as String),
      appVersion: manifest['appVersion'] as String,
      records: records,
      settings: settings,
      photos: photos,
      warnings: warnings,
    );
  }

  Future<RestoreResult> apply(
    RestorePlan plan, {
    RestoreStrategy strategy = RestoreStrategy.merge,
  }) async {
    final local = {for (final b in await _repository.getAllForSync()) b.id: b};
    var restored = 0, skipped = 0, conflicts = 0;
    final toApply = <Birthday>[];
    for (final incoming in plan.records) {
      final current = local[incoming.id];
      if (strategy == RestoreStrategy.merge && current != null) {
        final a = incoming.updatedAt, b = current.updatedAt;
        if (a == null || b == null) {
          conflicts++;
          continue;
        }
        if (!a.isAfter(b)) {
          skipped++;
          continue;
        }
      }
      toApply.add(incoming);
      restored++;
    }
    if (_repository case final TransactionalBirthdayRepository transactional) {
      await transactional.restoreBirthdaysTransactionally(
        toApply,
        replace: strategy == RestoreStrategy.replace,
      );
    } else {
      if (strategy == RestoreStrategy.replace) {
        for (final b in local.values) {
          await _repository.deleteBirthday(b.id);
        }
      }
      for (final b in toApply) {
        await _repository.upsertBirthday(b);
      }
    }
    for (final e in plan.settings.entries) {
      final v = e.value;
      if (v is String)
        await _preferences.setString(e.key, v);
      else if (v is bool)
        await _preferences.setBool(e.key, v);
      else if (v is int)
        await _preferences.setInt(e.key, v);
      else if (v is double)
        await _preferences.setDouble(e.key, v);
    }
    return RestoreResult(
      restored: restored,
      skipped: skipped,
      conflicts: conflicts,
      photosRestored: plan.photos.length,
      photosFailed: plan.warnings.where((w) => w.code == 'bad_photo').length,
      warnings: plan.warnings,
    );
  }
}
