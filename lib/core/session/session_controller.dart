import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'app_session_mode.dart';
import 'session_repository.dart';

/// Tracks the current [AppSessionMode]. Auth and local-mode toggles both
/// flow through here so widgets can listen with [ChangeNotifier] semantics.
class SessionController extends ChangeNotifier {
  SessionController({
    required SessionRepository repository,
    required Stream<User?> authStateChanges,
  })  : _repository = repository {
    _authSub = authStateChanges.listen(_onAuthChanged);
    _bootstrap();
  }

  final SessionRepository _repository;
  late final StreamSubscription<User?> _authSub;

  AppSessionMode _mode = AppSessionMode.unauthenticated;
  AppSessionMode get mode => _mode;

  bool _bootstrapDone = false;
  bool get isReady => _bootstrapDone;

  Future<void> _bootstrap() async {
    _mode = await _repository.resolveMode(
      isAuthenticated: _lastAuthenticated,
    );
    _bootstrapDone = true;
    notifyListeners();
  }

  bool _lastAuthenticated = false;
  Future<void> _onAuthChanged(User? user) async {
    _lastAuthenticated = user != null;
    _mode = await _repository.resolveMode(isAuthenticated: _lastAuthenticated);
    notifyListeners();
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
