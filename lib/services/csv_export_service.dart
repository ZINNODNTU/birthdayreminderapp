import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/birthday.dart';
import 'package:device_info_plus/device_info_plus.dart';

class CsvExportService {
  static Future<File?> exportBirthdaysToCsv(List<Birthday> birthdays) async {
    if (birthdays.isEmpty) {
      debugPrint("❌ No birthdays to export.");
      return null;
    }

    try {
      final permission = await _requestStoragePermission();
      if (!permission.isGranted) {
        debugPrint("❌ Storage permission denied.");
        return null;
      }

      final List<List<String>> rows = [];

      // Header
      rows.add([
        'ID',
        'Name',
        'Gender',
        'Nickname',
        'Relationship',
        'SolarBirthday',
        'LunarDay',
        'LunarMonth',
        'LunarYear',
        'CalendarType',
        'RemindBeforeDays',
        'RemindTime',
        'RecurringNotification',
        'RepeatAnnually',
        'Note',
      ]);

      // Data rows
      for (final b in birthdays) {
        rows.add([
          b.id,
          _escapeCsvField(b.name),
          _escapeCsvField(b.gender ?? ''),
          _escapeCsvField(b.nickname ?? ''),
          _escapeCsvField(b.relationship ?? ''),
          b.solarBirthday.toIso8601String(),
          b.lunarBirthday.day.toString(),
          b.lunarBirthday.month.toString(),
          b.lunarBirthday.year.toString(),
          b.calendarType.name,
          b.remindBeforeDays.toString(),
          _formatTimeOfDay(b.remindTime),
          b.isRecurringNotificationEnabled ? 'Yes' : 'No',
          b.repeatAnnually ? 'Yes' : 'No',
          _escapeCsvField(b.note ?? ''),
        ]);
      }

      final csv = const ListToCsvConverter().convert(rows);

      final directory = await _getExportDirectory();
      if (directory == null) {
        debugPrint("❌ Could not access export directory.");
        return null;
      }

      final folder = Directory('${directory.path}/BirthdayExports');
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      final fileName =
          'birthdays_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${folder.path}/$fileName');

      // Add UTF-8 BOM to support Vietnamese characters in Excel
      final encoded = '\uFEFF$csv';

      await file.writeAsString(encoded, flush: true);
      debugPrint('✅ CSV exported to: ${file.path}');

      return file;
    } catch (e, stack) {
      debugPrint('❌ Error exporting CSV: $e');
      debugPrint('$stack');
      return null;
    }
  }

  static Future<PermissionStatus> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        return await Permission.manageExternalStorage.request();
      } else {
        return await Permission.storage.request();
      }
    }
    return PermissionStatus.granted; // iOS
  }

  static Future<Directory?> _getExportDirectory() async {
    try {
      if (Platform.isAndroid) {
        final dirs = await getExternalStorageDirectories(
          type: StorageDirectory.downloads,
        );
        return dirs?.first ?? await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        return await getApplicationDocumentsDirectory();
      }
    } catch (e) {
      debugPrint('❌ Error getting export directory: $e');
    }
    return null;
  }

  static String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  static String _escapeCsvField(String input) {
    if (input.contains(',') || input.contains('"') || input.contains('\n')) {
      return '"${input.replaceAll('"', '""')}"';
    }
    return input;
  }
}
