import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/firestore/firestore_schema.dart';
import '../models/birthday.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Bạn cần đăng nhập để sử dụng sao lưu đám mây.');
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _birthdaysCollection =>
      _firestore
          .collection(FirestoreSchema.users)
          .doc(_uid)
          .collection(FirestoreSchema.birthdays);

  Future<void> backupBirthday(Birthday birthday) async {
    await _birthdaysCollection.doc(birthday.id).set({
      ...birthday.toMap(),
      'ownerId': _uid,
      'updatedAt': FieldValue.serverTimestamp(),
      'schemaVersion': 1,
    });
  }

  Future<List<Birthday>> getBackedUpBirthdays() async {
    final snapshot = await _birthdaysCollection.get();
    return snapshot.docs.map((doc) => Birthday.fromMap(doc.data())).toList();
  }

  Future<void> deleteAllBirthdays() async {
    final snapshot = await _birthdaysCollection.get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> deleteBackedUpBirthday(String id) {
    return _birthdaysCollection.doc(id).delete();
  }
}
