import 'package:birthdayreminderapp/controllers/birthday_controller.dart';
import 'package:birthdayreminderapp/core/auth/auth_gate.dart';
import 'package:birthdayreminderapp/core/auth/auth_repository.dart';
import 'package:birthdayreminderapp/core/auth/user_profile_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:birthdayreminderapp/core/session/session_controller.dart';
import 'package:birthdayreminderapp/core/session/session_repository.dart';
import 'package:birthdayreminderapp/features/auth/views/auth_screen.dart';
import 'package:birthdayreminderapp/features/birthdays/data/birthday_repository.dart';
import 'package:birthdayreminderapp/features/birthdays/data/local_birthday_repository.dart';
import 'package:birthdayreminderapp/features/birthdays/domain/birthday_engine.dart';
import 'package:birthdayreminderapp/features/birthdays/domain/default_birthday_engine.dart';
import 'package:birthdayreminderapp/features/birthdays/domain/lunar_calendar_service.dart';
import 'package:birthdayreminderapp/features/reminders/data/reminder_schedule_store.dart';
import 'package:birthdayreminderapp/features/reminders/services/notification_id_factory.dart';
import 'package:birthdayreminderapp/features/reminders/services/notification_permission_service.dart';
import 'package:birthdayreminderapp/features/reminders/services/reminder_scheduler.dart';
import 'package:birthdayreminderapp/services/local_db_service.dart';
import 'package:birthdayreminderapp/services/notification_service.dart';
import 'package:birthdayreminderapp/views/homepage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/fake_auth_repository.dart';

import 'package:birthdayreminderapp/l10n/app_localizations.dart';
import 'package:birthdayreminderapp/services/locale_service.dart';

import '../helpers/fake_notification_service.dart';

late SharedPreferences sharedPrefs;

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
    sharedPrefs = await SharedPreferences.getInstance();
  });

  testWidgets(
    'Tapping logout on Homepage signs out and returns to AuthScreen',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = FakeAuthRepository();
      repo.setUser(FakeUser('seed@example.com'));
      final sessionRepo = SessionRepository();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<LocalDbService>(create: (_) => LocalDbService()),
            Provider<NotificationService>.value(
              value: FakeNotificationService(),
            ),
            Provider<BirthdayRepository>(
              create:
                  (ctx) => LocalBirthdayRepository(ctx.read<LocalDbService>()),
            ),
            Provider<LunarCalendarService>(
              create: (_) => const LunarCalendarService(),
            ),
            Provider<BirthdayEngine>(
              create:
                  (ctx) =>
                      DefaultBirthdayEngine(ctx.read<LunarCalendarService>()),
            ),
            Provider<NotificationIdFactory>(
              create: (_) => const NotificationIdFactory(),
            ),
            Provider<NotificationPermissionService>(
              create: (_) => NotificationPermissionService(),
            ),
            Provider<ReminderScheduleStore>(
              create: (_) => ReminderScheduleStore(sharedPrefs),
            ),
            Provider<ReminderScheduler>(
              create:
                  (ctx) => ReminderScheduler(
                    engine: ctx.read<BirthdayEngine>(),
                    idFactory: ctx.read<NotificationIdFactory>(),
                    notificationService: ctx.read<NotificationService>(),
                    permissionService:
                        ctx.read<NotificationPermissionService>(),
                    store: ctx.read<ReminderScheduleStore>(),
                  ),
            ),
            ChangeNotifierProvider<BirthdayController>(
              create:
                  (ctx) => BirthdayController(
                    repository: ctx.read<BirthdayRepository>(),
                    reminderScheduler: ctx.read<ReminderScheduler>(),
                    notificationService: ctx.read<NotificationService>(),
                    engine: ctx.read<BirthdayEngine>(),
                  ),
            ),
            Provider<AuthRepository>.value(value: repo),
            Provider<UserProfileRepository>(
              create: (_) => _NoopProfileRepository(),
            ),
            Provider<SessionRepository>.value(value: sessionRepo),
            ChangeNotifierProvider<SessionController>(
              create:
                  (ctx) => SessionController(
                    repository: ctx.read<SessionRepository>(),
                    authRepository: ctx.read<AuthRepository>(),
                    profileRepository: ctx.read<UserProfileRepository>(),
                    authStateChanges:
                        ctx.read<AuthRepository>().authStateChanges,
                  ),
            ),
            ChangeNotifierProvider<LocaleService>(
              create: (_) => LocaleService(sharedPrefs),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: const [Locale('vi')],
            home: const AuthGate(),
          ),
        ),
      );
      await _settle(tester);

      expect(find.byType(Homepage), findsOneWidget);

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      final homepageCtx = tester.element(find.byType(Homepage));
      final l10n = AppLocalizations.of(homepageCtx);
      await tester.tap(find.text(l10n.signOut));
      await _settle(tester);

      expect(repo.signOutCalls, 1);
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.byType(Homepage), findsNothing);
    },
  );
}

class _NoopProfileRepository implements UserProfileRepository {
  @override
  Future<void> ensureProfile(User user) async {}
}
