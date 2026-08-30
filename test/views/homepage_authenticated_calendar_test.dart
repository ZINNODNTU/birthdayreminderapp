import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:birthdayreminderapp/controllers/birthday_controller.dart';
import 'package:birthdayreminderapp/core/auth/auth_gate.dart';
import 'package:birthdayreminderapp/core/auth/auth_repository.dart';
import 'package:birthdayreminderapp/core/auth/user_profile_repository.dart';
import 'package:birthdayreminderapp/core/session/app_session_mode.dart';
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
import 'package:birthdayreminderapp/views/calendar_view.dart';
import 'package:birthdayreminderapp/views/homepage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_notification_service.dart';
import '../helpers/fake_birthday_repository.dart';

class _NoopProfileRepo implements UserProfileRepository {
  @override
  Future<void> ensureProfile(User user) async {}
}

Widget _wrap({
  required AuthRepository repo,
  required SessionRepository sessionRepo,
  BirthdayRepository? birthdayRepo,
  FakeNotificationService? notifications,
}) {
  final fake = notifications ?? FakeNotificationService();
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
        create: (_) => const NotificationPermissionService(),
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
    ],
    child: const MaterialApp(home: AuthGate()),
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

late SharedPreferences sharedPrefs;

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
    'authenticated Homepage renders CalendarView (not blank) with zero birthdays',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = FakeAuthRepository()..setUser(FakeUser('test@example.com'));
      final sessionRepo = SessionRepository();
      final birthdayRepo = FakeBirthdayRepository();

      await tester.pumpWidget(
        _wrap(repo: repo, sessionRepo: sessionRepo, birthdayRepo: birthdayRepo),
      );
      await _settle(tester);

      expect(find.byType(Homepage), findsOneWidget);
      expect(find.byType(AuthScreen), findsNothing);

      expect(find.byType(CalendarView), findsOneWidget);
      expect(find.byType(TableCalendar), findsOneWidget);

      expect(find.byType(BottomAppBar), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);

      expect(find.text('Birthday Reminder'), findsOneWidget);
    },
  );

  testWidgets(
    'local Homepage renders CalendarView (not blank) with zero birthdays',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = FakeAuthRepository()..setUser(null);
      final sessionRepo = SessionRepository();
      await sessionRepo.setLocalModeEnabled(true);
      final birthdayRepo = FakeBirthdayRepository();

      await tester.pumpWidget(
        _wrap(repo: repo, sessionRepo: sessionRepo, birthdayRepo: birthdayRepo),
      );
      await _settle(tester);

      expect(find.byType(Homepage), findsOneWidget);
      expect(find.byType(CalendarView), findsOneWidget);
      expect(find.byType(TableCalendar), findsOneWidget);
    },
  );

  testWidgets(
    'AuthScreen -> Google sign-in -> Homepage renders CalendarView, no exceptions',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = FakeAuthRepository()..setUser(null);
      final sessionRepo = SessionRepository();
      final birthdayRepo = FakeBirthdayRepository();

      await tester.pumpWidget(
        _wrap(repo: repo, sessionRepo: sessionRepo, birthdayRepo: birthdayRepo),
      );
      await _settle(tester);

      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.byType(Homepage), findsNothing);

      final ctx = tester.element(find.byType(AuthGate));
      await ctx.read<SessionController>().signInWithGoogle();
      await _settle(tester);

      expect(find.byType(Homepage), findsOneWidget);
      expect(find.byType(AuthScreen), findsNothing);
      expect(find.byType(CalendarView), findsOneWidget);
      expect(find.byType(TableCalendar), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'local Homepage -> Google sign-in -> authenticated Homepage keeps Calendar',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = FakeAuthRepository()..setUser(null);
      final sessionRepo = SessionRepository();
      final birthdayRepo = FakeBirthdayRepository();

      await tester.pumpWidget(
        _wrap(repo: repo, sessionRepo: sessionRepo, birthdayRepo: birthdayRepo),
      );
      await _settle(tester);

      final ctx = tester.element(find.byType(AuthGate));
      await ctx.read<SessionController>().enableLocalMode();
      await _settle(tester);

      expect(find.byType(Homepage), findsOneWidget);
      expect(find.byType(CalendarView), findsOneWidget);

      await tester.dragFrom(
        tester.getTopLeft(find.byType(Homepage)) + const Offset(0, 200),
        const Offset(500, 0),
      );
      await _settle(tester);
      await tester.tap(
        find.byKey(const ValueKey('drawer_local_sign_in_google')),
      );
      await _settle(tester);

      final session =
          tester.element(find.byType(Homepage)).read<SessionController>();
      expect(session.mode, AppSessionMode.authenticated);
      expect(find.byType(CalendarView), findsOneWidget);
      expect(find.byType(TableCalendar), findsOneWidget);
    },
  );
}
