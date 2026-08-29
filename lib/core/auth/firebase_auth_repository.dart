import 'dart:async';

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

  StreamController<User?>? _stateController;
  StreamSubscription<User?>? _firebaseSub;

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Stream<User?> get authStateChanges {
    final controller = _stateController ??= StreamController<User?>.broadcast();
    scheduleMicrotask(() {
      if (!controller.isClosed) controller.add(_auth.currentUser);
    });
    _firebaseSub ??= _auth.authStateChanges().listen(controller.add);
    return controller.stream;
  }

  @override
  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleAuthClient.authenticate();
      if (googleUser == null) {
        throw AuthFailureCancelled();
      }
      final idToken = googleUser.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw AuthFailureUnknown();
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw AuthFailureUnknown();
      }
      final providers = user.providerData.map((p) => p.providerId).toList();
      if (!providers.contains('google.com')) {
        await _auth.signOut();
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
    } catch (_) {}
    await _auth.signOut();
  }
}
