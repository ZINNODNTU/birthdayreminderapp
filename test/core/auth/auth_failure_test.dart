import 'package:birthdayreminderapp/core/auth/auth_failure.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  group('AuthFailure.fromAny', () {
    test('maps network-request-failed', () {
      expect(
        AuthFailure.fromAny(_FakeAuthException('network-request-failed')),
        isA<AuthFailureNetwork>(),
      );
    });
    test('maps user-disabled', () {
      expect(
        AuthFailure.fromAny(_FakeAuthException('user-disabled')),
        isA<AuthFailureUserDisabled>(),
      );
    });
    test('maps operation-not-allowed', () {
      expect(
        AuthFailure.fromAny(_FakeAuthException('operation-not-allowed')),
        isA<AuthFailureOperationNotAllowed>(),
      );
    });
    test('maps too-many-requests', () {
      expect(
        AuthFailure.fromAny(_FakeAuthException('too-many-requests')),
        isA<AuthFailureTooManyRequests>(),
      );
    });
    test('maps cancellation (sign_in_canceled)', () {
      expect(
        AuthFailure.fromAny(_FakeAuthException('sign_in_canceled')),
        isA<AuthFailureCancelled>(),
      );
    });
    test('falls back to AuthFailureUnknown for unknown codes', () {
      expect(
        AuthFailure.fromAny(_FakeAuthException('made-up-code')),
        isA<AuthFailureUnknown>(),
      );
    });
    test('falls back to AuthFailureUnknown for non-Firebase exceptions', () {
      expect(AuthFailure.fromAny(Exception('boom')), isA<AuthFailureUnknown>());
    });
  });

  group('FakeAuthRepository behavior', () {
    test('signInWithGoogle tracks call and updates current user', () async {
      final repo = FakeAuthRepository();
      final user = await repo.signInWithGoogle();
      expect(repo.signInWithGoogleCalls, 1);
      expect(user, isNotNull);
      expect(repo.currentUser, isNotNull);
    });

    test('signInWithGoogle throws configured AuthFailure', () async {
      final repo = FakeAuthRepository()
        ..signInWithGoogleFailure = AuthFailureNetwork();
      expect(repo.signInWithGoogle(), throwsA(isA<AuthFailureNetwork>()));
    });

    test('signOut clears current user and tracks call', () async {
      final repo = FakeAuthRepository(initialUser: FakeUser('seed@b.com'));
      expect(repo.currentUser, isNotNull);
      await repo.signOut();
      expect(repo.signOutCalls, 1);
      expect(repo.currentUser, isNull);
    });
  });
}

/// Tolerant stand-in so we don't need to import every FirebaseAuthException
/// subclass for code-string tests.
class _FakeAuthException implements Exception {
  _FakeAuthException(this.code);
  final String code;
}
