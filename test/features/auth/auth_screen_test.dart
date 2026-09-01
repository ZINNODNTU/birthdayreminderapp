import 'package:birthdayreminderapp/core/auth/auth_failure.dart';
import 'package:birthdayreminderapp/core/auth/auth_repository.dart';
import 'package:birthdayreminderapp/core/auth/user_profile_repository.dart';
import 'package:birthdayreminderapp/core/session/app_session_mode.dart';
import 'package:birthdayreminderapp/core/session/session_controller.dart';
import 'package:birthdayreminderapp/core/session/session_repository.dart';
import 'package:birthdayreminderapp/features/auth/views/auth_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_auth_repository.dart';

import 'package:birthdayreminderapp/l10n/app_localizations.dart';
import 'package:birthdayreminderapp/services/locale_service.dart';

class _DelayedAuthRepository extends FakeAuthRepository {
  _DelayedAuthRepository();
  @override
  Future<User?> signInWithGoogle() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return super.signInWithGoogle();
  }
}

/// Trivial stub that satisfies the type-check without touching Firebase.
/// AuthScreen never calls the profile repository directly.
class _NoopProfileRepository implements UserProfileRepository {
  @override
  Future<void> ensureProfile(User user) async {}
}

late SharedPreferences sharedPrefs;

Widget _wrap(AuthRepository repo) {
  return MultiProvider(
    providers: [
      Provider<AuthRepository>.value(value: repo),
      Provider<UserProfileRepository>(create: (_) => _NoopProfileRepository()),
      ChangeNotifierProvider<SessionController>(
        create:
            (ctx) => SessionController(
              repository: SessionRepository(),
              authRepository: repo,
              profileRepository: ctx.read<UserProfileRepository>(),
              authStateChanges: repo.authStateChanges,
            ),
      ),
      ChangeNotifierProvider<LocaleService>(
        create: (_) => LocaleService(sharedPrefs),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const [Locale('vi')],
      home: const AuthScreen(),
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPrefs = await SharedPreferences.getInstance();
  });

  group('AuthScreen Google-only UI', () {
    testWidgets('shows Google and Local Mode buttons', (tester) async {
      final repo = FakeAuthRepository();
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(tester.element(find.byType(AuthScreen)));
      expect(find.text(l10n.signInGoogle), findsOneWidget);
      expect(find.text(l10n.continueOnDevice), findsOneWidget);
    });

    testWidgets('does NOT show email / password / register / forgot', (
      tester,
    ) async {
      final repo = FakeAuthRepository();
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      expect(find.text('Email'), findsNothing);
      expect(find.text('Mật khẩu'), findsNothing);
      expect(find.text('Đăng ký'), findsNothing);
      expect(find.text('Quên mật khẩu?'), findsNothing);
      expect(find.text('Đăng nhập'), findsNothing);
    });
  });

  group('Google sign-in flow', () {
    testWidgets('tap Google triggers signInWithGoogle', (tester) async {
      final repo = FakeAuthRepository();
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(tester.element(find.byType(AuthScreen)));
      await tester.tap(find.text(l10n.signInGoogle));
      await tester.pumpAndSettle();

      expect(repo.signInWithGoogleCalls, 1);
      expect(repo.currentUser, isNotNull);
    });

    testWidgets('cancellation is silent (no snackbar, AuthScreen stays)', (
      tester,
    ) async {
      final repo =
          FakeAuthRepository()
            ..signInWithGoogleFailure = AuthFailureCancelled();
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(tester.element(find.byType(AuthScreen)));
      await tester.tap(find.text(l10n.signInGoogle));
      await tester.pumpAndSettle();

      expect(repo.signInWithGoogleCalls, 1);
      expect(repo.currentUser, isNull);
      expect(find.byType(AuthScreen), findsOneWidget);
    });

    testWidgets('failure surfaces friendly Vietnamese message', (tester) async {
      final repo =
          FakeAuthRepository()..signInWithGoogleFailure = AuthFailureNetwork();
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(tester.element(find.byType(AuthScreen)));
      await tester.tap(find.text(l10n.signInGoogle));
      await tester.pumpAndSettle();

      expect(find.text(l10n.noInternet), findsOneWidget);
    });

    testWidgets('loading indicator blocks duplicate taps', (tester) async {
      final repo = _DelayedAuthRepository();
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(tester.element(find.byType(AuthScreen)));
      await tester.tap(find.text(l10n.signInGoogle));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Double-tap is a no-op because the button is disabled.
      await tester.tap(find.text(l10n.signInGoogle), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(repo.signInWithGoogleCalls, 1);
    });
  });

  group('Local Mode', () {
    testWidgets('tap Local Mode enables AppSessionMode.local', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final sessionRepo = SessionRepository();
      await sessionRepo.setLocalModeEnabled(false);

      final repo = FakeAuthRepository();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AuthRepository>.value(value: repo),
            Provider<UserProfileRepository>(
              create: (_) => _NoopProfileRepository(),
            ),
            Provider<SessionRepository>.value(value: sessionRepo),
            ChangeNotifierProvider<SessionController>(
              create:
                  (ctx) => SessionController(
                    repository: ctx.read<SessionRepository>(),
                    authRepository: repo,
                    profileRepository: ctx.read<UserProfileRepository>(),
                    authStateChanges: repo.authStateChanges,
                  ),
            ),
            ChangeNotifierProvider<LocaleService>(
              create: (_) => LocaleService(sharedPrefs),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: const [Locale('vi')],
            home: const AuthScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(tester.element(find.byType(AuthScreen)));
      await tester.tap(find.text(l10n.continueOnDevice));
      await tester.pumpAndSettle();

      final ctx = tester.element(find.byType(AuthScreen));
      expect(ctx.read<SessionController>().mode, AppSessionMode.local);
    });
  });
}
