import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:birthdayreminderapp/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:birthdayreminderapp/controllers/birthday_controller.dart';
import 'package:birthdayreminderapp/core/auth/auth_gate.dart';
import 'package:birthdayreminderapp/core/auth/firebase_auth_repository.dart';
import 'package:birthdayreminderapp/core/session/session_controller.dart';
import 'package:birthdayreminderapp/features/auth/views/auth_screen.dart';
import 'package:birthdayreminderapp/features/sync/sync_manager.dart';
import 'package:birthdayreminderapp/views/homepage.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/prod_parity_providers.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('vi_VN');
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'production AppDependencies.providers resolves every consumer (no ProviderNotFound)',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final authRepo = FakeAuthRepository();
      final providers = buildProdParityProviders(
        prefs: prefs,
        authRepositoryOverride: authRepo,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: providers,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: const [Locale('vi')],
            home: const AuthGate(),
          ),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      final ctx = tester.element(find.byType(AuthGate));
      expect(ctx.read<FirebaseAuthRepository>(), isNotNull);
      expect(ctx.read<BirthdayController>(), isNotNull);
      expect(ctx.read<SessionController>(), isNotNull);
      expect(ctx.read<SyncManager>(), isNotNull);

      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.byType(Homepage), findsNothing);
    },
  );

  testWidgets(
    'Google sign-in resolves BirthdayController + Homepage through prod tree',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final prefs = await SharedPreferences.getInstance();
      final authRepo = FakeAuthRepository();
      final providers = buildProdParityProviders(
        prefs: prefs,
        authRepositoryOverride: authRepo,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: providers,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: const [Locale('vi')],
            home: const AuthGate(),
          ),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.byType(AuthScreen), findsOneWidget);

      final ctx = tester.element(find.byType(AuthGate));
      await ctx.read<SessionController>().signInWithGoogle();
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // CRITICAL: if FirebaseAuthRepository was placed below
      // BirthdayController in production, this lookup throws and the
      // widget tree never reaches this state.
      expect(ctx.read<BirthdayController>(), isNotNull);
      expect(ctx.read<FirebaseAuthRepository>(), isNotNull);
      expect(find.byType(Homepage), findsOneWidget);
    },
  );

  testWidgets('Local mode resolves BirthdayController through prod tree', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final prefs = await SharedPreferences.getInstance();
    final authRepo = FakeAuthRepository()..setUser(null);
    final providers = buildProdParityProviders(
      prefs: prefs,
      authRepositoryOverride: authRepo,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: providers,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: const [Locale('vi')],
          home: const AuthGate(),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.byType(AuthScreen), findsOneWidget);

    final ctx = tester.element(find.byType(AuthGate));
    await ctx.read<SessionController>().enableLocalMode();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.byType(Homepage), findsOneWidget);
    expect(ctx.read<BirthdayController>(), isNotNull);
    expect(ctx.read<FirebaseAuthRepository>(), isNotNull);
  });
}
