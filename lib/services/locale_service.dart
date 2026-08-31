import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService extends ChangeNotifier {
  LocaleService(this._prefs)
    : _locale = Locale(_normalize(_prefs.getString(_key)));

  static const _key = 'app_locale';
  static const supportedCodes = {'vi', 'en', 'zh'};
  final SharedPreferences _prefs;
  Locale _locale;
  Locale get locale => _locale;

  static String _normalize(String? code) =>
      supportedCodes.contains(code) ? code! : 'vi';

  Future<void> setLocale(String code) async {
    final normalized = _normalize(code);
    if (_locale.languageCode == normalized) return;
    _locale = Locale(normalized);
    await _prefs.setString(_key, normalized);
    notifyListeners();
  }
}
