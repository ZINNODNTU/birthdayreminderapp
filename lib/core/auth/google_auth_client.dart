import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';

import '../logging/app_logger.dart';
import 'auth_failure.dart';

/// Thin adapter around `google_sign_in` 7.2.x.
///
/// Centralises the init lifecycle (the plugin throws
/// `GoogleSignInExceptionCode.clientConfigurationError` if you call
/// `authenticate()` before `initialize()` resolves) and exposes the
/// narrow contract the rest of the app needs.
abstract class GoogleAuthClient {
  Future<void> ensureInitialized();

  Future<GoogleSignInAccount?> authenticate();

  Future<void> signOut();
}

/// Production adapter. Wraps `GoogleSignIn.instance`.
class GoogleSignInClient implements GoogleAuthClient {
  GoogleSignInClient({GoogleSignIn? googleSignIn})
    : _google = googleSignIn ?? GoogleSignIn.instance;

  final GoogleSignIn _google;
  Future<void>? _initFuture;

  @override
  Future<void> ensureInitialized() {
    return _initFuture ??= _safeInit();
  }

  Future<void> _safeInit() async {
    try {
      await _google.initialize();
      AppLogger.info('GoogleAuthClient', 'google_sign_in initialized');
    } catch (e, st) {
      AppLogger.warn('GoogleAuthClient', 'initialize() failed: $e\n$st');
      rethrow;
    }
  }

  @override
  Future<GoogleSignInAccount?> authenticate() async {
    await ensureInitialized();
    if (!_google.supportsAuthenticate()) {
      throw AuthFailureUnknown();
    }
    return _google.authenticate();
  }

  @override
  Future<void> signOut() async {
    await ensureInitialized();
    await _google.signOut();
  }
}

/// In-memory fake for unit tests. Records every interaction.
class FakeGoogleAuthClient implements GoogleAuthClient {
  FakeGoogleAuthClient({
    this.account,
    this.initializeError,
    this.authenticateError,
  });

  GoogleSignInAccount? account;
  int initializeCalls = 0;
  int authenticateCalls = 0;
  int signOutCalls = 0;
  Object? initializeError;
  Object? authenticateError;

  @override
  Future<void> ensureInitialized() async {
    initializeCalls++;
    if (initializeError != null) throw initializeError!;
  }

  @override
  Future<GoogleSignInAccount?> authenticate() async {
    authenticateCalls++;
    if (authenticateError != null) throw authenticateError!;
    return account;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }
}
