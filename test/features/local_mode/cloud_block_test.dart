import 'package:birthdayreminderapp/controllers/birthday_controller.dart';
import 'package:birthdayreminderapp/core/auth/auth_gate.dart';
import 'package:birthdayreminderapp/core/auth/auth_repository.dart';
import 'package:birthdayreminderapp/core/session/app_session_mode.dart';
import 'package:birthdayreminderapp/core/session/session_controller.dart';
import 'package:birthdayreminderapp/core/session/session_repository.dart';
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

import '../../helpers/fake_auth_repository.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Widget _tree({
  required AuthRepository repo,
  required SessionRepository sessionRepo,
  BirthdayRepository? birthdayRepo,
}) {
  return MultiProvider(
    providers: [
      Provider<LocalDbService>(create: (_) => LocalDbService()),
      Provider<NotificationService>(create: (_) => NotificationService()),
      Provider<BirthdayRepository>(
        create: (ctx) => birthdayRepo ??
            LocalBirthdayRepository(ctx.read<LocalDbService>()),
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
    'In local mode, tapping "Backup lên Firestore" shows the auth-required snackbar',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = FakeAuthRepository();
      repo.setUser(null);
      final sessionRepo = SessionRepository();
      await sessionRepo.setLocalModeEnabled(true);

      await tester.pumpWidget(_tree(
        repo: repo,
        sessionRepo: sessionRepo,
      ));
      await _settle(tester);

      expect(find.byType(Homepage), findsOneWidget);
      final ctx = tester.element(find.byType(Homepage));
      final mode = ctx.read<SessionController>().mode;
      expect(mode, AppSessionMode.local);

      await tester.tap(find.byTooltip('Open navigation menu'));
      await _settle(tester);

      // The drawer is taller than the test viewport; scroll to the item.
      await tester.scrollUntilVisible(
        find.text('Sao lưu lên Firestore'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Sao lưu lên Firestore'));
      await _settle(tester);

      expect(
        find.text('Đăng nhập để sử dụng tính năng đồng bộ đám mây.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'In local mode, tapping "Xóa toàn bộ trên Firestore" also blocks gracefully',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = FakeAuthRepository();
      repo.setUser(null);
      final sessionRepo = SessionRepository();
      await sessionRepo.setLocalModeEnabled(true);

      await tester.pumpWidget(_tree(
        repo: repo,
        sessionRepo: sessionRepo,
      ));
      await _settle(tester);

      await tester.tap(find.byTooltip('Open navigation menu'));
      await _settle(tester);

      await tester.scrollUntilVisible(
        find.text('Xóa toàn bộ trên Firestore'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Xóa toàn bộ trên Firestore'));
      await _settle(tester);

      expect(
        find.text('Đăng nhập để sử dụng tính năng đồng bộ đám mây.'),
        findsOneWidget,
      );
    },
  );
}
