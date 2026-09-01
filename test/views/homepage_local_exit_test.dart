import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:birthdayreminderapp/controllers/birthday_controller.dart';
import 'package:birthdayreminderapp/core/auth/auth_gate.dart';
import 'package:birthdayreminderapp/core/auth/auth_repository.dart';
import 'package:birthdayreminderapp/core/auth/user_profile_repository.dart';
import 'package:birthdayreminderapp/core/session/session_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_notification_service.dart';

import 'package:birthdayreminderapp/l10n/app_localizations.dart';
import 'package:birthdayreminderapp/services/locale_service.dart';

Widget _wrap({
  required AuthRepository repo,
  required SessionRepository sessionRepo,
  BirthdayRepository? birthdayRepo,
  FakeNotificationService? fakeNotifications,
}) {
  final fake = fakeNotifications ?? FakeNotificationService();
  return MultiProvider(
    providers: [
      Provider<LocalDbService>(create: (_) => LocalDbService()),
      Provider<NotificationService>.value(value: fake),
      Provider<BirthdayRepository>(
        create:
            (ctx) =>
                birthdayRepo ??
                LocalBirthdayRepository(ctx.read<LocalDbService>()),
      ),
      Provider<LunarCalendarService>(
        create: (_) => const LunarCalendarService(),
      ),
      Provider<BirthdayEngine>(
        create:
            (ctx) => DefaultBirthdayEngine(ctx.read<LunarCalendarService>()),
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
              permissionService: ctx.read<NotificationPermissionService>(),
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
      Provider<UserProfileRepository>(create: (_) => _NoopProfileRepo()),
      Provider<SessionRepository>.value(value: sessionRepo),
      ChangeNotifierProvider<SessionController>(
        create:
            (ctx) => SessionController(
              repository: ctx.read<SessionRepository>(),
              authRepository: ctx.read<AuthRepository>(),
              profileRepository: ctx.read<UserProfileRepository>(),
              authStateChanges: ctx.read<AuthRepository>().authStateChanges,
            ),
      ),
      ChangeNotifierProvider<LocaleService>(
        create: (_) => LocaleService(sharedPrefs),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const [Locale('vi')],
      home: const AuthGate(),
    ),
  );
}

late SharedPreferences sharedPrefs;

class _NoopProfileRepo implements UserProfileRepository {
  @override
  Future<void> ensureProfile(User user) async {}
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

  testWidgets('local → exit → AuthScreen shows Google button', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = FakeAuthRepository();
    repo.setUser(null);
    final sessionRepo = SessionRepository();

    await tester.pumpWidget(_wrap(repo: repo, sessionRepo: sessionRepo));
    await tester.pumpAndSettle();

    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.byType(Homepage), findsNothing);

    // Enable local mode by tapping the button.
    await tester.tap(find.text('Tiếp tục trên thiết bị'));
    await tester.pumpAndSettle();

    expect(find.byType(Homepage), findsOneWidget);
    expect(find.byType(AuthScreen), findsNothing);

    // Get SessionController from the context of Homepage and disable local mode.
    final ctx = tester.element(find.byType(Homepage));
    await ctx.read<SessionController>().disableLocalMode();
    await tester.pumpAndSettle();

    // Should be back on AuthScreen with Google button.
    expect(find.byType(AuthScreen), findsOneWidget);
    final authCtx = tester.element(find.byType(AuthScreen));
    final l10n = AppLocalizations.of(authCtx);
    expect(find.text(l10n.signInGoogle), findsOneWidget);
  });
}
