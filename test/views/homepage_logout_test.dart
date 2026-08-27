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
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/fake_auth_repository.dart';

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
            Provider<NotificationService>(
              create: (_) => NotificationService(),
            ),
            Provider<BirthdayRepository>(
              create: (ctx) => LocalBirthdayRepository(
                ctx.read<LocalDbService>(),
              ),
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
                authStateChanges:
                    ctx.read<AuthRepository>().authStateChanges,
              ),
            ),
          ],
          child: const MaterialApp(home: AuthGate()),
        ),
      );
      await _settle(tester);

      expect(find.byType(Homepage), findsOneWidget);

      await tester.tap(find.byTooltip('Open navigation menu'));
      await _settle(tester);

      await tester.tap(find.text('Đăng xuất'));
      await _settle(tester);

      expect(repo.signOutCalls, 1);
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.byType(Homepage), findsNothing);
    },
  );
}
