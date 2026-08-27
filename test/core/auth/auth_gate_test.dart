import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:birthdayreminderapp/controllers/birthday_controller.dart';
import 'package:birthdayreminderapp/core/auth/auth_gate.dart';
import 'package:birthdayreminderapp/core/auth/auth_repository.dart';
import 'package:birthdayreminderapp/core/session/session_controller.dart';
import 'package:birthdayreminderapp/core/session/session_repository.dart';
import 'package:birthdayreminderapp/features/auth/views/auth_screen.dart';
import 'package:birthdayreminderapp/features/birthdays/data/birthday_repository.dart';
import 'package:birthdayreminderapp/features/birthdays/data/local_birthday_repository.dart';
import 'package:birthdayreminderapp/services/local_db_service.dart';
import 'package:birthdayreminderapp/services/notification_service.dart';
import 'package:birthdayreminderapp/views/homepage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/fake_auth_repository.dart';

Widget _wrap({
  required AuthRepository repo,
  required SessionRepository sessionRepo,
  BirthdayRepository? birthdayRepo,
}) {
  return MultiProvider(
    providers: [
      Provider<LocalDbService>(create: (_) => LocalDbService()),
      Provider<NotificationService>(create: (_) => NotificationService()),
      Provider<BirthdayRepository>(
        create: (ctx) =>
            birthdayRepo ?? LocalBirthdayRepository(ctx.read<LocalDbService>()),
      ),
      ChangeNotifierProvider<BirthdayController>(
        create: (ctx) => BirthdayController(
          repository: ctx.read<BirthdayRepository>(),
          notificationService: ctx.read<NotificationService>(),
        ),
      ),
      Provider<AuthRepository>.value(value: repo),
      Provider<SessionRepository>.value(value: sessionRepo),
      ChangeNotifierProvider<SessionController>(
        create: (ctx) => SessionController(
          repository: ctx.read<SessionRepository>(),
          authStateChanges: ctx.read<AuthRepository>().authStateChanges,
        ),
      ),
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
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await initializeDateFormatting('vi_VN');
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('AuthGate shows AuthScreen when unauthenticated and local off', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = FakeAuthRepository();
    repo.setUser(null);

    await tester.pumpWidget(_wrap(
      repo: repo,
      sessionRepo: SessionRepository(),
    ));
    await _settle(tester);

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

    await tester.pumpWidget(_wrap(
      repo: repo,
      sessionRepo: SessionRepository(),
    ));
    await _settle(tester);

    expect(find.byType(Homepage), findsOneWidget);
    expect(find.byType(AuthScreen), findsNothing);
  });

  testWidgets('AuthGate shows Homepage in local mode without auth', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = FakeAuthRepository();
    repo.setUser(null);
    final sessionRepo = SessionRepository();
    await sessionRepo.setLocalModeEnabled(true);

    await tester.pumpWidget(_wrap(
      repo: repo,
      sessionRepo: sessionRepo,
    ));
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
      await tester.pumpWidget(_wrap(
        repo: repo,
        sessionRepo: SessionRepository(),
      ));
      await _settle(tester);

      expect(find.byType(AuthScreen), findsOneWidget);

      await repo.signInWithEmail('a@b.com', 'pw');
      await _settle(tester);

      expect(find.byType(Homepage), findsOneWidget);
      expect(find.byType(AuthScreen), findsNothing);

      await repo.signOut();
      await _settle(tester);

      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.byType(Homepage), findsNothing);
    },
  );

  testWidgets('AuthGate switches to Homepage when "continue on device" tapped',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = FakeAuthRepository();
    repo.setUser(null);
    final sessionRepo = SessionRepository();

    await tester.pumpWidget(_wrap(
      repo: repo,
      sessionRepo: sessionRepo,
    ));
    await _settle(tester);

    expect(find.byType(AuthScreen), findsOneWidget);

    final ctx = tester.element(find.byType(AuthScreen));
    // Drive the same SessionController API that the button would call.
    await ctx.read<SessionController>().enableLocalMode();
    await _settle(tester);

    expect(find.byType(Homepage), findsOneWidget);
    expect(await sessionRepo.isLocalModeEnabled(), isTrue);
  });
}
