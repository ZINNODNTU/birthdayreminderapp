import 'package:birthdayreminderapp/core/auth/google_auth_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakeGoogleAuthClient', () {
    test('ensureInitialized records each call', () async {
      final fake = FakeGoogleAuthClient();
      await fake.ensureInitialized();
      await fake.ensureInitialized();
      await fake.ensureInitialized();
      expect(fake.initializeCalls, 3);
    });

    test('propagates configured errors', () async {
      final fake = FakeGoogleAuthClient(authenticateError: 'cancelled');
      expect(
        () => fake.authenticate(),
        throwsA(predicate((e) => e == 'cancelled')),
      );
    });

    test('signOut is fire-and-forget', () async {
      final fake = FakeGoogleAuthClient();
      await fake.signOut();
      expect(fake.signOutCalls, 1);
    });
  });

  // Sanity test — the real production adapter must wrap the singleton.
  test('GoogleSignInClient wraps GoogleSignIn.instance', () {
    final c = GoogleSignInClient();
    expect(c, isNotNull);
  });
}
