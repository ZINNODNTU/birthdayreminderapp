import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Generic authentication failure surfaced by [AuthRepository].
///
/// The mapping is deliberately narrow: only the Google Sign-In /
/// FirebaseAuth codes we actually handle are surfaced. Everything else
/// collapses to [AuthFailureUnknown] so callers don't need to special-case
/// every Firebase error string.
sealed class AuthFailure {
  const AuthFailure();
  static AuthFailure fromAny(Object? error) {
    if (error is AuthFailure) return error;
    String code = '';
    if (error is FirebaseAuthException) {
      code = error.code;
    } else if (error is GoogleSignInException) {
      code = error.code.name;
    } else {
      final dynamic dyn = error;
      try {
        final dynamic raw = dyn?.code;
        if (raw is String) {
          code = raw;
        } else if (raw is GoogleSignInExceptionCode) {
          code = raw.name;
        }
      } catch (_) {}
    }
    switch (code) {
      case 'network-request-failed':
        return AuthFailureNetwork();
      case 'user-disabled':
        return AuthFailureUserDisabled();
      case 'operation-not-allowed':
        return AuthFailureOperationNotAllowed();
      case 'too-many-requests':
        return AuthFailureTooManyRequests();
      case 'canceled':
      case 'sign_in_canceled':
      case 'userCanceled':
        return AuthFailureCancelled();
      case 'clientConfigurationError':
      case 'providerConfigurationError':
      case 'misconfiguredProvider':
        return AuthFailureConfiguration();
      case 'uiUnavailable':
      case 'interrupted':
        return AuthFailureUiUnavailable();
      default:
        return AuthFailureUnknown();
    }
  }
}

class AuthFailureNetwork extends AuthFailure {}

class AuthFailureUserDisabled extends AuthFailure {}

class AuthFailureOperationNotAllowed extends AuthFailure {}

class AuthFailureTooManyRequests extends AuthFailure {}

/// User dismissed the Google account chooser. Not a hard error.
class AuthFailureCancelled extends AuthFailure {}

/// Google Sign-In configuration error — usually means the OAuth client
/// isn't registered for the app's SHA fingerprint.
class AuthFailureConfiguration extends AuthFailure {}

/// Google Sign-In can't present the UI on this platform.
class AuthFailureUiUnavailable extends AuthFailure {}

class AuthFailureUnknown extends AuthFailure {}
