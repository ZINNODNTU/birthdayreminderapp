import 'package:shared_preferences/shared_preferences.dart';

import '../logging/app_logger.dart';
import 'app_session_mode.dart';

/// Persists whether the user has opted into local-only mode.
///
/// Stored as a single boolean preference. We never persist credentials;
/// Firebase Auth remains the source of truth for authentication.
class SessionRepository {
  SessionRepository({SharedPreferences? prefs}) : _prefsOverride = prefs;

  static const String _kLocalModeKey = 'session.localMode';

  final SharedPreferences? _prefsOverride;
  SharedPreferences? _cached;

  Future<SharedPreferences> _prefs() async {
    if (_prefsOverride != null) return _prefsOverride;
    return _cached ??= await SharedPreferences.getInstance();
  }

  Future<bool> isLocalModeEnabled() async {
    final prefs = await _prefs();
    return prefs.getBool(_kLocalModeKey) ?? false;
  }

  Future<void> setLocalModeEnabled(bool enabled) async {
    final prefs = await _prefs();
    await prefs.setBool(_kLocalModeKey, enabled);
    AppLogger.info('SessionRepository', 'localMode=$enabled');
  }

  Future<AppSessionMode> resolveMode({required bool isAuthenticated}) async {
    if (isAuthenticated) return AppSessionMode.authenticated;
    final local = await isLocalModeEnabled();
    return local ? AppSessionMode.local : AppSessionMode.unauthenticated;
  }

  Future<void> clearLocalMode() async {
    await setLocalModeEnabled(false);
  }
}
