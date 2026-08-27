import 'package:firebase_auth/firebase_auth.dart';

sealed class AuthFailure {
  const AuthFailure();
  static AuthFailure fromFirebase(dynamic e) {
    String code = '';
    if (e is FirebaseAuthException) {
      code = e.code;
    } else {
      // Test doubles may expose a `code` field/getter; respect it.
      final dynamic dyn = e;
      try {
        final dynamic raw = dyn?.code;
        if (raw is String) code = raw;
      } catch (_) {}
    }
    switch (code) {
      case 'network-request-failed':
        return AuthFailureNetwork();
      case 'invalid-email':
        return AuthFailureInvalidEmail();
      case 'invalid-credential':
        return AuthFailureInvalidCredential();
      case 'wrong-password':
        return AuthFailureWrongPassword();
      case 'user-not-found':
        return AuthFailureUserNotFound();
      case 'user-disabled':
        return AuthFailureUserDisabled();
      case 'email-already-in-use':
        return AuthFailureEmailAlreadyInUse();
      case 'weak-password':
        return AuthFailureWeakPassword();
      case 'operation-not-allowed':
        return AuthFailureOperationNotAllowed();
      case 'too-many-requests':
        return AuthFailureTooManyRequests();
      default:
        return AuthFailureUnknown();
    }
  }
}

class AuthFailureNetwork extends AuthFailure {}

class AuthFailureInvalidEmail extends AuthFailure {}

class AuthFailureInvalidCredential extends AuthFailure {}

class AuthFailureWrongPassword extends AuthFailure {}

class AuthFailureUserNotFound extends AuthFailure {}

class AuthFailureUserDisabled extends AuthFailure {}

class AuthFailureEmailAlreadyInUse extends AuthFailure {}

class AuthFailureWeakPassword extends AuthFailure {}

class AuthFailureOperationNotAllowed extends AuthFailure {}

class AuthFailureTooManyRequests extends AuthFailure {}

class AuthFailureUnknown extends AuthFailure {}
