import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_failure.dart';
import 'auth_repository.dart';

/// Google-only [AuthRepository] backed by Firebase Auth + Google Sign-In
/// (plugin v6/v7 API).
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  /// Cached current user; mirrored from Firebase Auth state.
  User? _currentUser;
  StreamController<User?>? _stateController;

  @override
  User? get currentUser => _auth.currentUser ?? _currentUser;

  @override
  Stream<User?> get authStateChanges {
    final controller = _stateController ??= StreamController<User?>.broadcast();
    // Replay current value immediately on subscribe.
    controller.add(_auth.currentUser);
    final sub = _auth.authStateChanges().listen(controller.add);
    controller.onCancel = () async {
      await sub.cancel();
    };
    return controller.stream;
  }

  @override
  Future<User?> signInWithGoogle() async {
    try {
      // 1. Trigger the native Google account chooser.
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // 2. Pull the ID token from the chosen account. The token
      //    is what Firebase needs to build a credential.
      final GoogleSignInAuthentication auth = googleUser.authentication;
      final String? idToken = auth.idToken;
      if (idToken == null) {
        throw AuthFailureUnknown();
      }

      // 3. Build a Firebase credential and sign in.
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw AuthFailureUnknown();
      }

      // 4. Defence-in-depth: only Google providers are allowed.
      final providers = user.providerData.map((p) => p.providerId).toList();
      if (!providers.contains('google.com')) {
        await _auth.signOut();
        throw AuthFailureOperationNotAllowed();
      }
      _currentUser = user;
      return user;
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw AuthFailure.fromAny(e);
    }
  }

  @override
  Future<void> signOut() async {
    // Disconnect from Google first; this clears the cached account
    // selection so the next sign-in shows the chooser again. We do NOT
    // call disconnect()/revoke access scopes — those actions remove
    // the user's grant permanently and are reserved for account
    // deletion flows.
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Best-effort: even if Google sign-out fails (e.g. plugin not
      // initialised in tests), we still want Firebase signed out.
    }
    await _auth.signOut();
    _currentUser = null;
  }
}
