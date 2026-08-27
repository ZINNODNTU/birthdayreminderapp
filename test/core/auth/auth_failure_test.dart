import 'package:birthdayreminderapp/core/auth/auth_failure.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/fake_auth_repository.dart';

void main() {
  group('AuthFailure.fromFirebase', () {
    test('maps network-request-failed', () {
      expect(
        AuthFailure.fromFirebase(_FakeAuthException('network-request-failed')),
        isA<AuthFailureNetwork>(),
      );
    });
    test('maps invalid-email', () {
      expect(
        AuthFailure.fromFirebase(_FakeAuthException('invalid-email')),
        isA<AuthFailureInvalidEmail>(),
      );
    });
    test('maps invalid-credential', () {
      expect(
        AuthFailure.fromFirebase(_FakeAuthException('invalid-credential')),
        isA<AuthFailureInvalidCredential>(),
      );
    });
    test('maps wrong-password', () {
      expect(
        AuthFailure.fromFirebase(_FakeAuthException('wrong-password')),
        isA<AuthFailureWrongPassword>(),
      );
    });
    test('maps user-not-found', () {
      expect(
        AuthFailure.fromFirebase(_FakeAuthException('user-not-found')),
        isA<AuthFailureUserNotFound>(),
      );
    });
    test('maps user-disabled', () {
      expect(
        AuthFailure.fromFirebase(_FakeAuthException('user-disabled')),
        isA<AuthFailureUserDisabled>(),
      );
    });
    test('maps email-already-in-use', () {
      expect(
        AuthFailure.fromFirebase(_FakeAuthException('email-already-in-use')),
        isA<AuthFailureEmailAlreadyInUse>(),
      );
    });
    test('maps weak-password', () {
      expect(
        AuthFailure.fromFirebase(_FakeAuthException('weak-password')),
        isA<AuthFailureWeakPassword>(),
      );
    });
    test('maps operation-not-allowed', () {
      expect(
        AuthFailure.fromFirebase(_FakeAuthException('operation-not-allowed')),
        isA<AuthFailureOperationNotAllowed>(),
      );
    });
    test('maps too-many-requests', () {
      expect(
        AuthFailure.fromFirebase(_FakeAuthException('too-many-requests')),
        isA<AuthFailureTooManyRequests>(),
      );
    });
    test('falls back to AuthFailureUnknown for unknown codes', () {
      expect(
        AuthFailure.fromFirebase(_FakeAuthException('made-up-code')),
        isA<AuthFailureUnknown>(),
      );
    });
    test('falls back to AuthFailureUnknown for non-Firebase exceptions', () {
      expect(
        AuthFailure.fromFirebase(Exception('boom')),
        isA<AuthFailureUnknown>(),
      );
    });
  });

  group('FakeAuthRepository behavior', () {
    test('signIn tracks call arguments and updates current user', () async {
      final repo = FakeAuthRepository();
      await repo.signInWithEmail('a@b.com', 'pw');
      expect(repo.signInCalls, 1);
      expect(repo.lastSignInEmail, 'a@b.com');
      expect(repo.lastSignInPassword, 'pw');
      expect(repo.currentUser, isNotNull);
      expect(repo.currentUser?.email, 'a@b.com');
    });

    test('signIn throws configured AuthFailure', () async {
      final repo =
          FakeAuthRepository()..signInFailure = AuthFailureInvalidCredential();
      expect(
        repo.signInWithEmail('a@b.com', 'pw'),
        throwsA(isA<AuthFailureInvalidCredential>()),
      );
    });

    test('register tracks call arguments', () async {
      final repo = FakeAuthRepository();
      await repo.registerWithEmail('new@b.com', 'pw');
      expect(repo.registerCalls, 1);
      expect(repo.lastRegisterEmail, 'new@b.com');
    });

    test('register throws configured AuthFailure', () async {
      final repo =
          FakeAuthRepository()..registerFailure = AuthFailureWeakPassword();
      expect(
        repo.registerWithEmail('a@b.com', 'pw'),
        throwsA(isA<AuthFailureWeakPassword>()),
      );
    });

    test('sendPasswordResetEmail tracks call', () async {
      final repo = FakeAuthRepository();
      await repo.sendPasswordResetEmail('a@b.com');
      expect(repo.resetCalls, 1);
      expect(repo.lastResetEmail, 'a@b.com');
    });

    test('sendPasswordResetEmail throws configured AuthFailure', () async {
      final repo =
          FakeAuthRepository()..resetFailure = AuthFailureUserNotFound();
      expect(
        repo.sendPasswordResetEmail('a@b.com'),
        throwsA(isA<AuthFailureUserNotFound>()),
      );
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

class _FakeAuthException implements Exception {
  _FakeAuthException(this.code);
  final String code;
}
