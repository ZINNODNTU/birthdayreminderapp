import 'package:birthdayreminderapp/features/onboarding/presentation/onboarding_screen.dart';
import 'package:birthdayreminderapp/features/onboarding/services/onboarding_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_birthday_repository.dart';

Future<SharedPreferences> _pump(
  WidgetTester tester, {
  bool manual = false,
  Size size = const Size(360, 800),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final service = OnboardingService(
    preferences: prefs,
    birthdays: FakeBirthdayRepository(),
  );
  await tester.pumpWidget(
    Provider<OnboardingService>.value(
      value: service,
      child: MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Builder(
            builder:
                (context) => Scaffold(
                  body: Center(
                    child: FilledButton(
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OnboardingScreen(manual: manual),
                            ),
                          ),
                      child: const Text('open'),
                    ),
                  ),
                ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return prefs;
}

void main() {
  testWidgets('renders page 1 and next opens page 2', (tester) async {
    await _pump(tester);
    expect(find.text('Chào mừng đến Birthday Reminder'), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding-primary')));
    await tester.pumpAndSettle();
    expect(find.text('Thêm sinh nhật thật nhanh'), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-dot-1')), findsOneWidget);
  });

  testWidgets('swipe changes pages', (tester) async {
    await _pump(tester);
    await tester.drag(
      find.byKey(const Key('onboarding-pages')),
      const Offset(-300, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Thêm sinh nhật thật nhanh'), findsOneWidget);
  });

  testWidgets('skip completes and closes', (tester) async {
    final prefs = await _pump(tester);
    await tester.tap(find.byKey(const Key('onboarding-skip')));
    await tester.pumpAndSettle();
    expect(prefs.getBool(OnboardingService.completedKey), isTrue);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('final CTA completes', (tester) async {
    final prefs = await _pump(tester);
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byKey(const Key('onboarding-primary')));
      await tester.pumpAndSettle();
    }
    expect(find.text('Bắt đầu sử dụng'), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding-primary')));
    await tester.pumpAndSettle();
    expect(prefs.getBool(OnboardingService.completedKey), isTrue);
  });

  testWidgets('manual mode closes without completing', (tester) async {
    final prefs = await _pump(tester, manual: true);
    expect(find.text('Đóng'), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding-skip')));
    await tester.pumpAndSettle();
    expect(prefs.containsKey(OnboardingService.completedKey), isFalse);
  });

  testWidgets('small screen and large text have no overflow', (tester) async {
    await _pump(tester, size: const Size(320, 640), textScale: 1.5);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
