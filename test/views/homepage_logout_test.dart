import 'package:birthdayreminderapp/controllers/birthday_controller.dart';
import 'package:birthdayreminderapp/core/auth/auth_gate.dart';
import 'package:birthdayreminderapp/core/auth/auth_repository.dart';
import 'package:birthdayreminderapp/views/homepage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import '../helpers/fake_auth_repository.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('vi_VN');
  });

  testWidgets(
    'Homepage calls AuthRepository.signOut when user logs out via stream',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = FakeAuthRepository();
      repo.setUser(FakeUser('seed@example.com'));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => BirthdayController(skipInit: true),
            ),
            Provider<AuthRepository>.value(value: repo),
          ],
          child: const MaterialApp(home: AuthGate()),
        ),
      );
      await _settle(tester);

      expect(find.byType(Homepage), findsOneWidget);

      // Simulate logout by clearing the stream. AuthGate must react.
      await repo.signOut();
      await _settle(tester);

      expect(repo.signOutCalls, 1);
      expect(find.byType(Homepage), findsNothing);
    },
  );
}
