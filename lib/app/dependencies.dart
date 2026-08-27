import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../controllers/birthday_controller.dart';
import '../core/auth/firebase_auth_repository.dart';
import '../core/session/session_controller.dart';
import '../core/session/session_repository.dart';
import '../features/birthdays/data/birthday_repository.dart';
import '../features/birthdays/data/local_birthday_repository.dart';
import '../features/birthdays/domain/birthday_engine.dart';
import '../features/birthdays/domain/default_birthday_engine.dart';
import '../features/birthdays/domain/lunar_calendar_service.dart';
import '../services/local_db_service.dart';
import '../services/notification_service.dart';

/// Single composition root. Every dependency that the widget tree needs
/// must be obtainable from here. Widgets must not call `FooService()`
/// themselves — that means injecting into the tree via this class.
class AppDependencies {
  const AppDependencies._();

  /// Build the provider list. Tests can override individual entries via
  /// their own MultiProvider wrapping.
  static List<SingleChildWidget> providers() {
    return [
      Provider<LocalDbService>(create: (_) => LocalDbService()),
      Provider<NotificationService>(create: (_) => NotificationService()),
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
      ChangeNotifierProvider<BirthdayController>(
        create:
            (ctx) => BirthdayController(
              repository: ctx.read<BirthdayRepository>(),
              notificationService: ctx.read<NotificationService>(),
              engine: ctx.read<BirthdayEngine>(),
            ),
      ),
      Provider<FirebaseAuthRepository>(create: (_) => FirebaseAuthRepository()),
      Provider<SessionRepository>(create: (_) => SessionRepository()),
      ChangeNotifierProvider<SessionController>(
        create:
            (ctx) => SessionController(
              repository: ctx.read<SessionRepository>(),
              authStateChanges:
                  ctx.read<FirebaseAuthRepository>().authStateChanges,
            ),
      ),
    ];
  }
}
