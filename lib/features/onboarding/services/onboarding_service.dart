import 'package:shared_preferences/shared_preferences.dart';

import '../../birthdays/data/birthday_repository.dart';

class OnboardingService {
  OnboardingService({
    required SharedPreferences preferences,
    required BirthdayRepository birthdays,
  }) : _preferences = preferences,
       _birthdays = birthdays;

  static const completedKey = 'onboarding_completed_v1';
  final SharedPreferences _preferences;
  final BirthdayRepository _birthdays;

  Future<bool> shouldShow() async {
    if (_preferences.containsKey(completedKey)) {
      return !(_preferences.getBool(completedKey) ?? false);
    }
    final hasEstablishedPreferences = _preferences.getKeys().isNotEmpty;
    final hasBirthdays = (await _birthdays.getAllForSync()).isNotEmpty;
    if (hasEstablishedPreferences || hasBirthdays) {
      await complete();
      return false;
    }
    return true;
  }

  Future<void> complete() => _preferences.setBool(completedKey, true);
}
