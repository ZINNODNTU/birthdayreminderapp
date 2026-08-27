import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:birthdayreminderapp/core/auth/auth_gate.dart';
import 'package:birthdayreminderapp/core/auth/auth_repository.dart';
import 'package:birthdayreminderapp/controllers/birthday_controller.dart';
import 'package:birthdayreminderapp/features/auth/views/auth_screen.dart';
import 'package:birthdayreminderapp/views/homepage.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../helpers/fake_auth_repository.dart';

Widget _wrap(AuthRepository repo) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => BirthdayController(skipInit: true)),
      Provider<AuthRepository>.value(value: repo),
    ],
    child: const MaterialApp(home: AuthGate()),
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('vi_VN');
  });

  testWidgets('AuthGate shows AuthScreen when unauthenticated', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = FakeAuthRepository();
    repo.setUser(null);

    await tester.pumpWidget(_wrap(repo));

    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.byType(Homepage), findsNothing);
  });

  testWidgets('AuthGate shows Homepage when authenticated', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = FakeAuthRepository();
    repo.setUser(FakeUser('test@example.com'));

    await tester.pumpWidget(_wrap(repo));
    await _settle(tester);

    expect(find.byType(Homepage), findsOneWidget);
    expect(find.byType(AuthScreen), findsNothing);
  });

  testWidgets(
    'AuthGate switches from AuthScreen to Homepage after sign-in via repository',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = FakeAuthRepository();
      await tester.pumpWidget(_wrap(repo));
      await _settle(tester);

      expect(find.byType(AuthScreen), findsOneWidget);

      // Trigger sign-in via the repository; this mirrors what AuthScreen.submit
      // does and is what AuthGate listens for.
      await repo.signInWithEmail('a@b.com', 'pw');
      await _settle(tester);

      expect(find.byType(Homepage), findsOneWidget);
      expect(find.byType(AuthScreen), findsNothing);

      // And the reverse.
      await repo.signOut();
      await _settle(tester);

      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.byType(Homepage), findsNothing);
    },
  );
}
