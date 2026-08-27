import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

/// Google-only authentication contract.
///
/// The app no longer supports email/password registration, login, or
/// password reset. Users authenticate with their Google account, or they
/// continue on device (handled by [SessionController], not this class).
abstract class AuthRepository {
  /// Currently signed-in Firebase user, or `null` if anonymous/local.
  User? get currentUser;

  /// Stream of authentication state changes emitted by Firebase.
  Stream<User?> get authStateChanges;

  /// Begin the Google Sign-In flow.
  ///
  /// Returns the signed-in [User] on success, `null` if the user
  /// cancelled the Google account chooser.
  ///
  /// Throws an [AuthFailure] (or platform exception) on network, Firebase
  /// or configuration errors.
  Future<User?> signInWithGoogle();

  /// Sign out from both Firebase and the Google Sign-In plugin.
  Future<void> signOut();
}
