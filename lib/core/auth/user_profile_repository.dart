import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../firestore/firestore_schema.dart';

/// Manages the canonical `/users/{uid}` profile document.
///
/// Responsibilities:
///   * Ensure the profile exists after a fresh Google sign-in.
///   * Refresh `lastLoginAt` on subsequent sign-ins without overwriting
///     `createdAt`.
///   * Never persist Google tokens, password, or refresh tokens.
class UserProfileRepository {
  UserProfileRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Schema version we write. Bumped only when a destructive migration
  /// is required.
  static const int schemaVersion = FirestoreSchema.version;

  DocumentReference<Map<String, dynamic>> _profileDoc(String uid) {
    return _db.collection(FirestoreSchema.users).doc(uid);
  }

  /// Create the profile document if it does not already exist; otherwise
  /// refresh `lastLoginAt` and `updatedAt`. Idempotent.
  Future<void> ensureProfile(User user) async {
    if (user.uid.isEmpty) {
      throw ArgumentError('Cannot create profile for empty uid');
    }
    final doc = _profileDoc(user.uid);
    final snap = await doc.get();
    final now = FieldValue.serverTimestamp();
    if (!snap.exists) {
      await doc.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoURL,
        'provider': _primaryProvider(user),
        'createdAt': now,
        'updatedAt': now,
        'lastLoginAt': now,
        'schemaVersion': schemaVersion,
      });
      return;
    }
    // Update only the mutable fields; createdAt is immutable.
    await doc.update({
      'email': user.email,
      'displayName': user.displayName,
      'photoUrl': user.photoURL,
      'lastLoginAt': now,
      'updatedAt': now,
    });
  }

  /// Resolve the user's primary provider — must be Google in production.
  String _primaryProvider(User user) {
    for (final info in user.providerData) {
      if (info.providerId.isNotEmpty) return info.providerId;
    }
    return 'unknown';
  }
}
