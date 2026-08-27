import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Tracks the (notificationId, scheduleKey, fingerprint) tuples the
/// app currently has scheduled on the OS. The store does not store
/// personal birthday data — only integers and short opaque keys.
class ReminderScheduleStore {
  ReminderScheduleStore(this._prefs);

  static const String _managedIdsKey = 'reminder_managed_ids';
  static const String _scheduleFingerprintKey =
      'reminder_schedule_fingerprints';

  final SharedPreferences _prefs;

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
    final result = <String, ManagedReminderEntry>{};
    for (final encoded in ids) {
      // encoded form: "scheduleKey|notificationId"
      final sep = encoded.indexOf('|');
      if (sep <= 0) continue;
      final scheduleKey = encoded.substring(0, sep);
      final idStr = encoded.substring(sep + 1);
      final id = int.tryParse(idStr);
      if (id == null) continue;
      result[scheduleKey] = ManagedReminderEntry(
        scheduleKey: scheduleKey,
        notificationId: id,
        fingerprint: (fpMap[scheduleKey] as String?) ?? '',
      );
    }
    return result;
  }

  /// Replace the entire managed set. Atomic from the caller's
  /// perspective — both lists are written.
  Future<void> saveAll(Map<String, ManagedReminderEntry> entries) async {
    final idLines = <String>[];
    final fpMap = <String, String>{};
    for (final entry in entries.values) {
      idLines.add('${entry.scheduleKey}|${entry.notificationId}');
      fpMap[entry.scheduleKey] = entry.fingerprint;
    }
    await _prefs.setStringList(_managedIdsKey, idLines);
    await _prefs.setString(_scheduleFingerprintKey, jsonEncode(fpMap));
  }

  Future<void> clear() async {
    await _prefs.remove(_managedIdsKey);
    await _prefs.remove(_scheduleFingerprintKey);
  }
}

class ManagedReminderEntry {
  const ManagedReminderEntry({
    required this.scheduleKey,
    required this.notificationId,
    required this.fingerprint,
  });

  final String scheduleKey;
  final int notificationId;
  final String fingerprint;
}
