import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:birthdayreminderapp/app/dependencies.dart';
import 'package:birthdayreminderapp/core/auth/firebase_auth_repository.dart';
import 'package:birthdayreminderapp/core/auth/google_auth_client.dart';
import 'package:birthdayreminderapp/core/auth/user_profile_repository.dart';
import 'package:birthdayreminderapp/features/birthdays/data/birthday_remote_repository.dart';
import 'package:birthdayreminderapp/services/local_db_service.dart';
import 'package:birthdayreminderapp/services/notification_service.dart';

import 'fake_birthday_remote_repository.dart';
import 'fake_notification_service.dart';

class _NoopProfileRepo implements UserProfileRepository {
  @override
  Future<void> ensureProfile(User user) async {}
}

/// Wraps the **real** production provider list (`AppDependencies.providers`)
/// with test-only overrides at the lowest platform boundary so that
/// every other provider is exercised exactly as production would do it.
///
/// The point of this helper is regression detection of provider-order
/// bugs: if `BirthdayController` ever moves above `FirebaseAuthRepository`
/// in the production list, tests that pump this helper will fail with
/// `ProviderNotFoundException`.
///
/// Platform-touching providers (Firebase / Firestore / native plugins)
/// are skipped in the production list and replaced with test doubles:
///   - FirebaseAuthRepository   -> caller-supplied fake
///   - GoogleAuthClient         -> caller-supplied fake (optional)
///   - UserProfileRepository    -> noop (no Firestore calls)
///   - BirthdayRemoteRepository -> FakeBirthdayRemoteRepository
///   - NotificationService      -> FakeNotificationService (optional)
///   - LocalDbService           -> caller-supplied fake (optional)
List<SingleChildWidget> buildProdParityProviders({
  required SharedPreferences prefs,
  required FirebaseAuthRepository authRepositoryOverride,
  GoogleAuthClient? googleAuthClientOverride,
  NotificationService? notificationServiceOverride,
  LocalDbService? localDbServiceOverride,
}) {
  final production = AppDependencies.providers(prefs);

  bool isType(SingleChildWidget p, String typeName) =>
      p.runtimeType.toString() == typeName;

  final filtered = production.where((p) {
    if (isType(p, 'Provider<FirebaseAuthRepository>')) return false;
    if (isType(p, 'Provider<UserProfileRepository>')) return false;
    if (isType(p, 'Provider<BirthdayRemoteRepository>')) return false;
    if (googleAuthClientOverride != null &&
        isType(p, 'Provider<GoogleAuthClient>')) {
      return false;
    }
    if (notificationServiceOverride != null &&
        isType(p, 'Provider<NotificationService>')) {
      return false;
    }
    if (localDbServiceOverride != null &&
        isType(p, 'Provider<LocalDbService>')) {
      return false;
    }
    return true;
  }).toList();

  final overrides = <SingleChildWidget>[
    if (localDbServiceOverride != null)
      Provider<LocalDbService>.value(value: localDbServiceOverride),
    if (notificationServiceOverride != null)
      Provider<NotificationService>.value(value: notificationServiceOverride)
    else
      Provider<NotificationService>.value(value: FakeNotificationService()),
    if (googleAuthClientOverride != null)
      Provider<GoogleAuthClient>.value(value: googleAuthClientOverride),
    Provider<FirebaseAuthRepository>.value(value: authRepositoryOverride),
    Provider<UserProfileRepository>.value(value: _NoopProfileRepo()),
    Provider<BirthdayRemoteRepository>.value(
      value: FakeBirthdayRemoteRepository(),
    ),
  ];

  return [...overrides, ...filtered];
}
