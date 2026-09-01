import 'package:firebase_auth/firebase_auth.dart';

import 'auth_failure.dart';
import 'auth_repository.dart';
import 'google_auth_client.dart';

/// Google-only [AuthRepository] backed by Firebase Auth + the
/// [GoogleAuthClient] adapter.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? auth,
    GoogleAuthClient? googleAuthClient,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _googleAuthClient = googleAuthClient ?? GoogleSignInClient();

  final FirebaseAuth _auth;
  final GoogleAuthClient _googleAuthClient;

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleAuthClient.authenticate();
      if (googleUser == null) throw AuthFailureCancelled();
      final idToken = googleUser.authentication.idToken;
      if (idToken == null || idToken.isEmpty) throw AuthFailureUnknown();

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final user = (await _auth.signInWithCredential(credential)).user;
      if (user == null) throw AuthFailureUnknown();

      final providers = user.providerData.map((p) => p.providerId);
      if (!providers.contains(GoogleAuthProvider.PROVIDER_ID)) {
        throw AuthFailureOperationNotAllowed();
      }
      return user;
    } on AuthFailure {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromAny(e);
    } catch (e) {
      throw AuthFailure.fromAny(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleAuthClient.signOut();
    } catch (_) {
      // Firebase sign-out must still complete if Google Play Services fails.
    }
    await _auth.signOut();
  }
}
