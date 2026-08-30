import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/birthday_controller.dart';
import '../core/auth/firebase_auth_repository.dart';
import '../core/auth/google_auth_client.dart';
import '../core/auth/user_profile_repository.dart';
import '../core/session/session_controller.dart';
import '../core/session/session_repository.dart';
import '../features/ai/data/ai_cache_storage.dart';
import '../features/ai/data/ai_config_repository.dart';
import '../features/ai/services/ai_client.dart';
import '../features/ai/services/birthday_ai_service.dart';
import '../features/reminders/services/legacy_schedule_migrator.dart';
import '../features/reminders/services/legacy_v3_migrator.dart';
import '../features/birthdays/data/birthday_firestore_mapper.dart';
import '../features/birthdays/data/birthday_remote_repository.dart';
import '../features/birthdays/data/birthday_repository.dart';
import '../features/birthdays/data/local_birthday_repository.dart';
import '../features/birthdays/domain/birthday_engine.dart';
import '../features/birthdays/domain/default_birthday_engine.dart';
import '../features/birthdays/domain/lunar_calendar_service.dart';
import '../features/birthdays/services/birthday_photo_service.dart';
import '../features/onboarding/services/onboarding_service.dart';
import '../features/reminders/data/reminder_schedule_store.dart';
import '../features/reminders/services/notification_id_factory.dart';
import '../features/reminders/services/notification_permission_service.dart';
import '../features/reminders/services/notification_reconciler.dart';
import '../features/reminders/services/reminder_scheduler.dart';
import '../features/sync/sync_manager.dart';
import '../features/update/repositories/github_release_repository.dart';
import '../features/update/services/app_update_service.dart';
import '../services/local_db_service.dart';
import '../services/notification_service.dart';

/// Single composition root. Every dependency that the widget tree
/// needs must be obtainable from here. Widgets must not call
/// `FooService()` themselves — they consume via the tree.
///
/// **Provider ordering invariant:** every `ctx.read<T>` inside a
/// `create:` callback resolves the *first* provider of type `T` that
/// appears ABOVE it in the list. Therefore each provider must be
/// declared after all of its dependencies and before all of its
/// consumers. The current order is:
///
///   shared infra -> auth foundations -> profile/session repos
///   -> birthday repos -> domain services -> reminder services
///   -> sync manager -> controllers (BirthdayController, SessionController)
class AppDependencies {
  const AppDependencies._();

  /// Build the provider list given an already-resolved
  /// [SharedPreferences] instance. Tests call
  /// `SharedPreferences.setMockInitialValues({})` and pass the result
  /// of `getInstance()`; production calls `getInstance()` once in
  /// `main()` before `runApp`.
  static List<SingleChildWidget> providers(SharedPreferences prefs) {
    return [
      // ---- shared infrastructure -------------------------------------
      Provider<SharedPreferences>.value(value: prefs),
      Provider<LocalDbService>(create: (_) => LocalDbService()),
      Provider<NotificationService>(create: (_) => NotificationService()),

      // ---- auth foundations (consumed by every auth-aware provider) --
      Provider<GoogleAuthClient>(create: (_) => GoogleSignInClient()),
      Provider<FirebaseAuthRepository>(create: (_) => FirebaseAuthRepository()),

      // ---- profile / session repos -----------------------------------
      Provider<UserProfileRepository>(create: (_) => UserProfileRepository()),
      Provider<SessionRepository>(create: (_) => SessionRepository()),

      // ---- birthday data layer ---------------------------------------
      Provider<BirthdayFirestoreMapper>.value(
        value: const BirthdayFirestoreMapper(),
      ),
      Provider<BirthdayRepository>(
        create: (ctx) => LocalBirthdayRepository(ctx.read<LocalDbService>()),
      ),
      Provider<BirthdayRemoteRepository>(
        create:
            (ctx) => FirestoreBirthdayRemoteRepository(
              mapper: ctx.read<BirthdayFirestoreMapper>(),
            ),
      ),
      Provider<OnboardingService>(
        create:
            (ctx) => OnboardingService(
              preferences: ctx.read<SharedPreferences>(),
              birthdays: ctx.read<BirthdayRepository>(),
            ),
      ),

      // ---- domain services -------------------------------------------
      Provider<BirthdayPhotoService>(
        create: (_) => const BirthdayPhotoService(),
      ),
      Provider<LunarCalendarService>(
        create: (_) => const LunarCalendarService(),
      ),
      Provider<BirthdayEngine>(
        create:
            (ctx) => DefaultBirthdayEngine(ctx.read<LunarCalendarService>()),
      ),

      // ---- AI configuration (non-secret in prefs, keys in secure storage) ----
      Provider<AiConfigRepository>(
        create:
            (ctx) => AiConfigRepository(prefs: ctx.read<SharedPreferences>()),
      ),
      Provider<AiClient>(create: (_) => AiClient()),
      Provider<AiCacheStorage>(
        create: (ctx) => AiCacheStorage(ctx.read<SharedPreferences>()),
      ),
      Provider<BirthdayAiService>(
        create:
            (ctx) => BirthdayAiService(
              configRepository: ctx.read<AiConfigRepository>(),
              client: ctx.read<AiClient>(),
              cacheStorage: ctx.read<AiCacheStorage>(),
            ),
      ),

      // ---- reminder services -----------------------------------------
      Provider<NotificationIdFactory>(
        create: (_) => const NotificationIdFactory(),
      ),
      Provider<NotificationPermissionService>(
        create: (_) => const NotificationPermissionService(),
      ),
      Provider<ReminderScheduleStore>(
        create: (ctx) => ReminderScheduleStore(ctx.read<SharedPreferences>()),
      ),
      Provider<LegacyScheduleMigrator>(
        create:
            (ctx) => LegacyScheduleMigrator(
              store: ctx.read<ReminderScheduleStore>(),
              notificationService: ctx.read<NotificationService>(),
            ),
      ),
      Provider<LegacyToV3Migrator>(
        create:
            (ctx) => LegacyToV3Migrator(
              store: ctx.read<ReminderScheduleStore>(),
              notificationService: ctx.read<NotificationService>(),
            ),
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

      // ---- sync manager (after auth + local + remote repos) -----------
      Provider<SyncManager>(
        create:
            (ctx) => SyncManager(
              local: ctx.read<BirthdayRepository>(),
              remote: ctx.read<BirthdayRemoteRepository>(),
              authGate: ctx.read<FirebaseAuthRepository>().authStateChanges,
              uidProvider:
                  () =>
                      ctx.read<FirebaseAuthRepository>().currentUser?.uid ?? '',
              photoService: ctx.read<BirthdayPhotoService>(),
            ),
        dispose: (_, mgr) => mgr.dispose(),
      ),

      // ---- update service --------------------------------------------
      Provider<GithubReleaseRepository>(
        create: (_) => GithubReleaseRepository(),
      ),
      ChangeNotifierProvider<AppUpdateService>(
        create:
            (ctx) => AppUpdateService(
              repository: ctx.read<GithubReleaseRepository>(),
              prefs: ctx.read<SharedPreferences>(),
            ),
      ),
      // ---- controllers (last, depend on everything above) ------------
      ChangeNotifierProvider<BirthdayController>(
        create:
            (ctx) => BirthdayController(
              repository: ctx.read<BirthdayRepository>(),
              reminderScheduler: ctx.read<ReminderScheduler>(),
              notificationService: ctx.read<NotificationService>(),
              engine: ctx.read<BirthdayEngine>(),
              authRepository: ctx.read<FirebaseAuthRepository>(),
              syncManager: ctx.read<SyncManager>(),
            ),
      ),
      ChangeNotifierProvider<SessionController>(
        create:
            (ctx) => SessionController(
              repository: ctx.read<SessionRepository>(),
              authRepository: ctx.read<FirebaseAuthRepository>(),
              profileRepository: ctx.read<UserProfileRepository>(),
              authStateChanges:
                  ctx.read<FirebaseAuthRepository>().authStateChanges,
            ),
      ),
    ];
  }
}
