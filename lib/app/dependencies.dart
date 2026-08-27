import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/birthday_controller.dart';
import '../core/auth/firebase_auth_repository.dart';
import '../core/auth/user_profile_repository.dart';
import '../core/session/session_controller.dart';
import '../core/session/session_repository.dart';
import '../features/birthdays/data/birthday_repository.dart';
import '../features/birthdays/data/local_birthday_repository.dart';
import '../features/birthdays/domain/birthday_engine.dart';
import '../features/birthdays/domain/default_birthday_engine.dart';
import '../features/birthdays/domain/lunar_calendar_service.dart';
import '../features/reminders/data/reminder_schedule_store.dart';
import '../features/reminders/services/notification_id_factory.dart';
import '../features/reminders/services/notification_permission_service.dart';
import '../features/reminders/services/notification_reconciler.dart';
import '../features/reminders/services/reminder_scheduler.dart';
import '../services/local_db_service.dart';
import '../services/notification_service.dart';

/// Single composition root. Every dependency that the widget tree
/// needs must be obtainable from here. Widgets must not call
/// `FooService()` themselves — they consume via the tree.
class AppDependencies {
  const AppDependencies._();

  /// Build the provider list given an already-resolved
  /// [SharedPreferences] instance. Tests call
  /// `SharedPreferences.setMockInitialValues({})` and pass the result
  /// of `getInstance()`; production calls `getInstance()` once in
  /// `main()` before `runApp`.
  static List<SingleChildWidget> providers(SharedPreferences prefs) {
    return [
      Provider<SharedPreferences>.value(value: prefs),
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
      Provider<NotificationIdFactory>(
        create: (_) => const NotificationIdFactory(),
      ),
      Provider<NotificationPermissionService>(
        create: (_) => const NotificationPermissionService(),
      ),
      Provider<ReminderScheduleStore>(
        create: (ctx) => ReminderScheduleStore(ctx.read<SharedPreferences>()),
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
      Provider<NotificationReconciler>(
        create:
            (ctx) => NotificationReconciler(
              repository: ctx.read<BirthdayRepository>(),
              scheduler: ctx.read<ReminderScheduler>(),
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
      Provider<FirebaseAuthRepository>(create: (_) => FirebaseAuthRepository()),
      Provider<UserProfileRepository>(create: (_) => UserProfileRepository()),
      Provider<SessionRepository>(create: (_) => SessionRepository()),
      ChangeNotifierProvider<SessionController>(
        create:
            (ctx) => SessionController(
              repository: ctx.read<SessionRepository>(),
              profileRepository: ctx.read<UserProfileRepository>(),
              authStateChanges:
                  ctx.read<FirebaseAuthRepository>().authStateChanges,
            ),
      ),
    ];
  }
}
