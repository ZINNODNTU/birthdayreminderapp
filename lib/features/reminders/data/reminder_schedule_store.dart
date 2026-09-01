import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Tracks the (notificationId, scheduleKey, fingerprint) tuples the
/// app currently has scheduled on the OS. The store does not store
/// personal birthday data — only integers and short opaque keys.
///
/// Schema v3 (current):
///   *  scheduleKey shape: `birthday:<id>:next`
///   *  one ACTIVE entry per birthday — the next pending reminder
///   *  reminder_schedule_schema_version = 3
///
/// Schema v2 (legacy, still parsed for migration):
///   *  scheduleKey shape: `birthday:<id>:year:<year>:primary`
///   *  up to 3 future occurrences per birthday
///
/// Schema v1 (legacy, still parsed for migration):
///   *  scheduleKey shape: `birthday:<id>:daysBefore:<N>:h:<HH>:m:<MM>`
class ReminderScheduleStore {
  ReminderScheduleStore(this._prefs);

  static const String _managedIdsKey = 'reminder_managed_ids';
  static const String _scheduleFingerprintKey =
      'reminder_schedule_fingerprints';
  static const String _scheduleDetailsKey = 'reminder_schedule_details_v1';
  static const String _schemaVersionKey = 'reminder_schedule_schema_version';

  /// Current schema version — bumped when the scheduleKey shape changes
  /// and a migration must run.
  static const int currentSchemaVersion = 3;

  final SharedPreferences _prefs;

  int get schemaVersion => _prefs.getInt(_schemaVersionKey) ?? 1;

  Future<void> setSchemaVersion(int v) async {
    await _prefs.setInt(_schemaVersionKey, v);
  }

  /// Load all currently managed entries.
  Map<String, ManagedReminderEntry> loadAll() {
    final ids = _prefs.getStringList(_managedIdsKey) ?? <String>[];
    final fpsRaw = _prefs.getString(_scheduleFingerprintKey) ?? '{}';
    Map<String, dynamic> fpMap;
    try {
      fpMap = jsonDecode(fpsRaw) as Map<String, dynamic>;
    } catch (_) {
      fpMap = <String, dynamic>{};
    }
    final detailsRaw = _prefs.getString(_scheduleDetailsKey) ?? '{}';
    Map<String, dynamic> details;
    try {
      details = jsonDecode(detailsRaw) as Map<String, dynamic>;
    } catch (_) {
      details = <String, dynamic>{};
    }
    final result = <String, ManagedReminderEntry>{};
    for (final encoded in ids) {
      final sep = encoded.indexOf('|');
      if (sep <= 0) continue;
      final scheduleKey = encoded.substring(0, sep);
      final idStr = encoded.substring(sep + 1);
      final id = int.tryParse(idStr);
      if (id == null) continue;
      final detail =
          (details[scheduleKey] as Map<String, dynamic>?) ?? const {};
      result[scheduleKey] = ManagedReminderEntry(
        scheduleKey: scheduleKey,
        notificationId: id,
        fingerprint: (fpMap[scheduleKey] as String?) ?? '',
        scheduledAt: _parseDate(detail['scheduledAt']),
        birthdayId: (detail['birthdayId'] as String?) ?? '',
        displayName: (detail['displayName'] as String?) ?? '',
        exact: (detail['exact'] as bool?) ?? false,
      );
    }
    return result;
  }

  /// Replace the entire managed set. Atomic from the caller's
  /// perspective — both lists are written.
  Future<void> saveAll(Map<String, ManagedReminderEntry> entries) async {
    final idLines = <String>[];
    final fpMap = <String, String>{};
    final details = <String, Map<String, dynamic>>{};
    for (final entry in entries.values) {
      idLines.add('${entry.scheduleKey}|${entry.notificationId}');
      fpMap[entry.scheduleKey] = entry.fingerprint;
      details[entry.scheduleKey] = {
        if (entry.birthdayId.isNotEmpty) 'birthdayId': entry.birthdayId,
        if (entry.displayName.isNotEmpty) 'displayName': entry.displayName,
        if (entry.scheduledAt != null)
          'scheduledAt': entry.scheduledAt!.toIso8601String(),
        'exact': entry.exact,
      };
    }
    await _prefs.setStringList(_managedIdsKey, idLines);
    await _prefs.setString(_scheduleFingerprintKey, jsonEncode(fpMap));
    await _prefs.setString(_scheduleDetailsKey, jsonEncode(details));
  }

  Future<void> clear() async {
    await _prefs.remove(_managedIdsKey);
    await _prefs.remove(_scheduleFingerprintKey);
    await _prefs.remove(_scheduleDetailsKey);
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw is String && raw.isNotEmpty) {
      try {
        return DateTime.parse(raw);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}

class ManagedReminderEntry {
  const ManagedReminderEntry({
    required this.scheduleKey,
    required this.notificationId,
    required this.fingerprint,
    this.scheduledAt,
    this.birthdayId = '',
    this.displayName = '',
    this.exact = false,
  });

  final String scheduleKey;
  final int notificationId;
  final String fingerprint;
  final DateTime? scheduledAt;
  final String birthdayId;
  final String displayName;
  final bool exact;
}
