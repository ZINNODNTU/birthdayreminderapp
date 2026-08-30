import 'package:birthdayreminderapp/features/onboarding/services/onboarding_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_birthday_repository.dart';

void main() {
  test('new user shouldShow true', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final service = OnboardingService(
      preferences: prefs,
      birthdays: FakeBirthdayRepository(),
    );
    expect(await service.shouldShow(), isTrue);
  });

  test('complete makes shouldShow false', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final service = OnboardingService(
      preferences: prefs,
      birthdays: FakeBirthdayRepository(),
    );
    await service.complete();
    expect(await service.shouldShow(), isFalse);
  });

  test('existing preference migrates without forced onboarding', () async {
    SharedPreferences.setMockInitialValues({'session.localMode': true});
    final prefs = await SharedPreferences.getInstance();
    final service = OnboardingService(
      preferences: prefs,
      birthdays: FakeBirthdayRepository(),
    );
    expect(await service.shouldShow(), isFalse);
    expect(prefs.getBool(OnboardingService.completedKey), isTrue);
  });

  test('completed preference is respected', () async {
    SharedPreferences.setMockInitialValues({
      OnboardingService.completedKey: true,
    });
    final prefs = await SharedPreferences.getInstance();
    final service = OnboardingService(
      preferences: prefs,
      birthdays: FakeBirthdayRepository(),
    );
    expect(await service.shouldShow(), isFalse);
  });
}
