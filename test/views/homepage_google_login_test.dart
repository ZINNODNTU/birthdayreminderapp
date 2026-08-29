import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:birthdayreminderapp/controllers/birthday_controller.dart';
import 'package:birthdayreminderapp/core/auth/auth_gate.dart';
import 'package:birthdayreminderapp/core/auth/auth_repository.dart';
import 'package:birthdayreminderapp/core/auth/user_profile_repository.dart';
import 'package:birthdayreminderapp/core/session/app_session_mode.dart';
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

late SharedPreferences sharedPrefs;

class _NoopProfileRepo implements UserProfileRepository {
  @override
  Future<void> ensureProfile(User user) async {}
}

/// Production-parity provider tree mirroring [AppDependencies.providers].
/// Production registers FirebaseAuthRepository concrete.
/// Homepage must not perform AuthRepository provider lookup.
/// SessionController receives auth dependency at composition root.
/// UI depends on SessionController only.
class _ProdParityTree extends StatelessWidget {
  const _ProdParityTree({required this.repo, required this.sessionRepo});

  final FakeAuthRepository repo;
  final SessionRepository sessionRepo;

  @override
  Widget build(BuildContext context) {
    final fakeNotifications = FakeNotificationService();
    return MultiProvider(
      providers: [
        Provider<LocalDbService>(create: (_) => LocalDbService()),
        Provider<NotificationService>.value(value: fakeNotifications),
        Provider<BirthdayRepository>(
          create: (ctx) => LocalBirthdayRepository(ctx.read<LocalDbService>()),
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
        Provider<UserProfileRepository>(create: (_) => _NoopProfileRepo()),
        Provider<SessionRepository>.value(value: sessionRepo),
        ChangeNotifierProvider<SessionController>(
          create:
              (ctx) => SessionController(
                repository: sessionRepo,
                authRepository: repo,
                profileRepository: ctx.read<UserProfileRepository>(),
                authStateChanges: repo.authStateChanges,
              ),
        ),
      ],
      child: const MaterialApp(home: AuthGate()),
    );
  }
}

/// Open the start-side [Drawer] by dragging from the left edge, then settle.
Future<void> _openDrawer(WidgetTester tester) async {
  final homepage = find.byType(Homepage);
  await tester.dragFrom(
    tester.getTopLeft(homepage) + const Offset(0, 200),
    const Offset(500, 0),
  );
  await tester.pumpAndSettle();
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
    'local mode can sign in with Google from Homepage without ProviderNotFoundException',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = FakeAuthRepository()..setUser(null);
      final sessionRepo = SessionRepository();
      await tester.pumpWidget(
        _ProdParityTree(repo: repo, sessionRepo: sessionRepo),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.byType(Homepage), findsNothing);

      await tester.tap(find.text('Tiếp tục trên thiết bị'));
      await tester.pumpAndSettle();
      expect(find.byType(Homepage), findsOneWidget);
      expect(find.byType(AuthScreen), findsNothing);

      await _openDrawer(tester);
      await tester.tap(
        find.byKey(const ValueKey('drawer_local_sign_in_google')),
      );
      await tester.pumpAndSettle();

      expect(repo.signInWithGoogleCalls, 1);
      expect(find.byType(Homepage), findsOneWidget);
      final session =
          tester.element(find.byType(Homepage)).read<SessionController>();
      expect(session.mode, AppSessionMode.authenticated);
    },
  );

  testWidgets('Homepage dependency providers are reachable', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = FakeAuthRepository()..setUser(null);
    final sessionRepo = SessionRepository();
    await tester.pumpWidget(
      _ProdParityTree(repo: repo, sessionRepo: sessionRepo),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tiếp tục trên thiết bị'));
    await tester.pumpAndSettle();
    expect(find.byType(Homepage), findsOneWidget);

    final ctx = tester.element(find.byType(Homepage));
    expect(ctx.read<SessionController>(), isNotNull);
    expect(ctx.read<BirthdayController>(), isNotNull);
  });

  testWidgets('authenticated -> sign out -> AuthScreen', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = FakeAuthRepository()..setUser(null);
    final sessionRepo = SessionRepository();
    await tester.pumpWidget(
      _ProdParityTree(repo: repo, sessionRepo: sessionRepo),
    );
    await tester.pumpAndSettle();

    await tester
        .element(find.byType(AuthGate))
        .read<SessionController>()
        .signInWithGoogle();
    await tester.pumpAndSettle();
    expect(find.byType(Homepage), findsOneWidget);

    // Drain the BirthdayController.loadBirthdays sqflite 10s timer so no
    // pending timers survive widget teardown.
    await tester.pumpAndSettle();
    expect(find.byType(Homepage), findsOneWidget);

    // Drain the BirthdayController.loadBirthdays sqflite 10s timer so no
    // pending timers survive widget teardown.
    await tester.pump(const Duration(seconds: 12));

    await _openDrawer(tester);
    await tester.tap(find.byKey(const ValueKey('drawer_sign_out')));
    await tester.pumpAndSettle();
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(repo.signOutCalls, 1);
  });
}
