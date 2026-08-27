import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:birthdayreminderapp/core/auth/auth_repository.dart';
import 'package:birthdayreminderapp/core/auth/auth_failure.dart';

/// Minimal in-memory User double. Overrides every member of the [User]
/// interface so the fake stays compatible with any firebase_auth bump that
/// tightens the contract.
class FakeUser implements User {
  FakeUser(this._email, {this.uid = 'fake-uid'});
  final String _email;
  @override
  final String uid;

  @override
  String get email => _email;
  @override
  String? get displayName => null;
  @override
  String? get photoURL => null;
  @override
  String? get phoneNumber => null;
  @override
  String? get tenantId => null;
  @override
  bool get emailVerified => false;
  @override
  bool get isAnonymous => false;
  @override
  MultiFactor get multiFactor => throw UnimplementedError();
  @override
  List<UserInfo> get providerData => [];
  @override
  Future<void> delete() => Future.value();
  @override
  Future<void> reload() => Future.value();
  @override
  Future<void> sendEmailVerification([
    ActionCodeSettings? actionCodeSettings,
  ]) => Future.value();
  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) =>
      throw UnimplementedError();
  @override
  Future<UserCredential> reauthenticateWithCredential(
    AuthCredential credential,
  ) => throw UnimplementedError();
  @override
  Future<User> unlink(String providerId) => Future.value(this);
  @override
  Future<void> updateDisplayName(String? displayName) => Future.value();
  @override
  Future<void> updateEmail(String newEmail) => Future.value();
  @override
  Future<void> updatePassword(String newPassword) => Future.value();
  @override
  Future<void> updatePhoneNumber(PhoneAuthCredential phoneCredential) =>
      Future.value();
  @override
  Future<void> updatePhotoURL(String? photoURL) => Future.value();
  @override
  Future<void> verifyBeforeUpdateEmail(
    String newEmail, [
    ActionCodeSettings? actionCodeSettings,
  ]) => Future.value();
  Map<String, dynamic> toJson() => {};

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async => null;
  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) async =>
      throw UnimplementedError();
  @override
  Future<ConfirmationResult> linkWithPhoneNumber(
    String phoneNumber, [
    RecaptchaVerifier? verifier,
  ]) async => throw UnimplementedError();
  @override
  Future<UserCredential> linkWithPopup(AuthProvider provider) async =>
      throw UnimplementedError();
  @override
  Future<UserCredential> linkWithProvider(AuthProvider provider) async =>
      throw UnimplementedError();
  @override
  Future<void> linkWithRedirect(AuthProvider provider) async =>
      throw UnimplementedError();
  @override
  UserMetadata get metadata => throw UnimplementedError();
  @override
  Future<UserCredential> reauthenticateWithPopup(AuthProvider provider) async =>
      throw UnimplementedError();
  @override
  Future<UserCredential> reauthenticateWithProvider(
    AuthProvider provider,
  ) async => throw UnimplementedError();
  @override
  Future<void> reauthenticateWithRedirect(AuthProvider provider) async =>
      throw UnimplementedError();
  @override
  String? get refreshToken => null;
  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) async =>
      Future.value();
}

/// Behavior-controllable AuthRepository double.
///
/// - Tracks how many times each method was invoked.
/// - Lets each call succeed by default or throw an [AuthFailure] set via
///   [signInFailure] / [registerFailure] / [resetFailure].
/// - Stream-based auth state so [AuthGate] rebuilds.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({User? initialUser}) {
    if (initialUser != null) {
      _user = initialUser;
    }
  }

  User? _user;
  final List<StreamController<User?>> _listeners = [];

  void _emit(User? user) {
    _user = user;
    for (final c in List<StreamController<User?>>.from(_listeners)) {
      c.add(user);
    }
  }

  int signInCalls = 0;
  int registerCalls = 0;
  int resetCalls = 0;
  int signOutCalls = 0;
  String? lastSignInEmail;
  String? lastSignInPassword;
  String? lastRegisterEmail;
  String? lastRegisterPassword;
  String? lastResetEmail;

  AuthFailure? signInFailure;
  AuthFailure? registerFailure;
  AuthFailure? resetFailure;

  @override
  User? get currentUser => _user;
  @override
  Stream<User?> get authStateChanges {
    final controller = StreamController<User?>.broadcast();
    _listeners.add(controller);
    controller.onCancel = () => _listeners.remove(controller);
    // Replay current user so subscribers get the latest state immediately.
    scheduleMicrotask(() {
      if (!controller.isClosed) controller.add(_user);
    });
    return controller.stream;
  }

  void setUser(User? user) => _emit(user);

  @override
  Future<void> signInWithEmail(String email, String password) async {
    signInCalls++;
    lastSignInEmail = email;
    lastSignInPassword = password;
    final failure = signInFailure;
    if (failure != null) throw failure;
    setUser(FakeUser(email));
  }

  @override
  Future<void> registerWithEmail(String email, String password) async {
    registerCalls++;
    lastRegisterEmail = email;
    lastRegisterPassword = password;
    final failure = registerFailure;
    if (failure != null) throw failure;
    setUser(FakeUser(email));
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    resetCalls++;
    lastResetEmail = email;
    final failure = resetFailure;
    if (failure != null) throw failure;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    setUser(null);
  }

  void dispose() {
    for (final c in _listeners) {
      c.close();
    }
    _listeners.clear();
  }
}
