import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  User? get currentUser;
  Stream<User?> get authStateChanges;
  Future<void> signInWithEmail(String email, String password);
  Future<void> registerWithEmail(String email, String password);
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
}
