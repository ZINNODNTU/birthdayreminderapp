import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../auth/user_profile_repository.dart';
import 'app_session_mode.dart';
import 'session_repository.dart';

/// Tracks the current [AppSessionMode]. Auth and local-mode toggles both
/// flow through here so widgets can listen with [ChangeNotifier] semantics.
///
/// On every fresh Google sign-in we also call
/// [UserProfileRepository.ensureProfile] so the canonical
/// `/users/{uid}` document exists before the user reaches the homepage.
/// SyncManager (Phase 5) handles birthday migration separately — it is
/// intentionally not triggered here.
class SessionController extends ChangeNotifier {
  SessionController({
    required SessionRepository repository,
    required UserProfileRepository profileRepository,
    required Stream<User?> authStateChanges,
  }) : _repository = repository,
       _profileRepository = profileRepository {
    _authSub = authStateChanges.listen(_onAuthChanged);
    _bootstrap();
  }

  final SessionRepository _repository;
  final UserProfileRepository _profileRepository;
  late final StreamSubscription<User?> _authSub;

  AppSessionMode _mode = AppSessionMode.unauthenticated;
  AppSessionMode get mode => _mode;

  bool _bootstrapDone = false;
  bool get isReady => _bootstrapDone;

  Future<void> _bootstrap() async {
    _mode = await _repository.resolveMode(isAuthenticated: _lastAuthenticated);
    _bootstrapDone = true;
    notifyListeners();
  }

  bool _lastAuthenticated = false;
  Future<void> _onAuthChanged(User? user) async {
    _lastAuthenticated = user != null;
    _mode = await _repository.resolveMode(isAuthenticated: _lastAuthenticated);
    notifyListeners();
    if (user != null) {
      try {
        await _profileRepository.ensureProfile(user);
      } catch (e, st) {
        // Profile creation is best-effort here — even if Firestore is
        // unavailable, the user can still use the app locally with the
        // SQLite cache. We log the failure and continue.
        FlutterError.reportError(
          FlutterErrorDetails(exception: e, stack: st, library: 'session'),
        );
      }
    }
  }

  /// Called from the AuthScreen when the user taps "Tiếp tục trên thiết bị".
  Future<void> enableLocalMode() async {
    if (_lastAuthenticated) return; // ignore in authenticated state
    await _repository.setLocalModeEnabled(true);
    _mode = AppSessionMode.local;
    notifyListeners();
  }

  /// Reset local mode flag (e.g. when the user signs out and chooses the
  /// cloud flow next time).
  Future<void> disableLocalMode() async {
    await _repository.setLocalModeEnabled(false);
    _mode = await _repository.resolveMode(isAuthenticated: _lastAuthenticated);
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }
}
