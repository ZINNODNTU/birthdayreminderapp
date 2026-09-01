import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../auth/auth_failure.dart';
import '../auth/auth_repository.dart';
import '../auth/user_profile_repository.dart';
import '../logging/app_logger.dart';
import 'app_session_mode.dart';
import 'session_repository.dart';

/// Tracks the current [AppSessionMode]. Auth and local-mode toggles both
/// flow through here so widgets can listen with [ChangeNotifier] semantics.
///
/// State machine:
///
///   unauthenticated
///     -- enterLocalMode()  -->  local
///     -- signInWithGoogle() -->  authenticated
///   local
///     -- exitLocalMode()   -->  unauthenticated
///     -- signInWithGoogle() -->  authenticated
///   authenticated
///     -- signOut()         -->  unauthenticated
///
/// On every fresh Google sign-in we also call
/// [UserProfileRepository.ensureProfile] so the canonical
/// `/users/{uid}` document exists before the user reaches the homepage.
/// SyncManager (Phase 5) handles birthday migration separately — it is
/// intentionally not triggered here.
class SessionController extends ChangeNotifier {
  SessionController({
    required SessionRepository repository,
    required AuthRepository authRepository,
    required UserProfileRepository profileRepository,
    required Stream<User?> authStateChanges,
  }) : _repository = repository,
       _authRepository = authRepository,
       _profileRepository = profileRepository {
    _user = authRepository.currentUser;
    _lastAuthenticated = _user != null;
    _authSub = authStateChanges.listen(_onAuthChanged);
    _bootstrap();
  }

  final SessionRepository _repository;
  final AuthRepository _authRepository;
  final UserProfileRepository _profileRepository;
  late final StreamSubscription<User?> _authSub;

  AppSessionMode _mode = AppSessionMode.unauthenticated;
  AppSessionMode get mode => _mode;

  User? _user;
  User? get user => _user;

  bool _bootstrapDone = false;
  bool get isReady => _bootstrapDone;

  /// True if the current device has opted into local mode at least once.
  Future<bool> isLocalModePersisted() => _repository.isLocalModeEnabled();

  Future<void> _bootstrap() async {
    final mode = await _repository.resolveMode(
      isAuthenticated: _lastAuthenticated,
    );
    if (!_bootstrapDone) _mode = mode;
    _bootstrapDone = true;
    notifyListeners();
  }

  bool _lastAuthenticated = false;

  Future<void> _onAuthChanged(User? user) async {
    _lastAuthenticated = user != null;
    _user = user;
    _mode = await _repository.resolveMode(isAuthenticated: user != null);
    _bootstrapDone = true;
    notifyListeners();
    if (user != null) {
      // Best-effort — Firestore being unavailable should never block
      // local use of the app.
      try {
        await _profileRepository.ensureProfile(user);
      } catch (e, st) {
        AppLogger.warn('SessionController', 'ensureProfile failed: $e\n$st');
      }
    }
  }

  // ---------------------------------------------------------------------
  // Local Mode transitions
  // ---------------------------------------------------------------------

  /// Persist local-mode flag and switch [mode] to [AppSessionMode.local].
  Future<void> enterLocalMode() async {
    if (_lastAuthenticated) return; // ignore when signed in
    await _repository.setLocalModeEnabled(true);
    _mode = AppSessionMode.local;
    notifyListeners();
  }

  /// Legacy alias — kept for backward compatibility with AuthScreen.
  Future<void> enableLocalMode() => enterLocalMode();

  /// Clear local-mode flag and return to [AppSessionMode.unauthenticated].
  Future<void> exitLocalMode() async {
    await _repository.setLocalModeEnabled(false);
    // Drop any localOnly migration hints the UI might be holding.
    _mode = AppSessionMode.unauthenticated;
    notifyListeners();
  }

  /// Legacy alias — kept for backward compatibility with tests.
  Future<void> disableLocalMode() => exitLocalMode();

  // ---------------------------------------------------------------------
  // Google sign-in / sign-out transitions
  // ---------------------------------------------------------------------

  /// Drive the Google Sign-In flow through [AuthRepository] and update
  /// [mode] based on the result. Throws [AuthFailure] on errors.
  Future<void> signInWithGoogle() async {
    await _authRepository.signInWithGoogle();
    // AuthGate rebuilds via the authStateChanges stream.
    _repository.setLocalModeEnabled(false);
  }

  /// Sign out from both Firebase and Google. Returns to
  /// [AppSessionMode.unauthenticated].
  Future<void> signOut() async {
    await _authRepository.signOut();
    // authStateChanges will emit null shortly; _onAuthChanged will
    // re-resolve the mode. Clear the local flag too so the user
    // returns to AuthScreen rather than the local Homepage.
    await _repository.setLocalModeEnabled(false);
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }
}
