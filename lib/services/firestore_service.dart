import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/birthday.dart';

class FirestoreService {
  final CollectionReference _birthdaysCollection = FirebaseFirestore.instance.collection('birthdays');

  Future<void> backupBirthday(Birthday birthday) async {
    await _birthdaysCollection.doc(birthday.id).set(birthday.toMap());
  }

  Future<List<Birthday>> getBackedUpBirthdays() async {
    final snapshot = await _birthdaysCollection.get();
    return snapshot.docs.map((doc) => Birthday.fromMap(doc.data() as Map<String, dynamic>)).toList();
  }
  Future<void> deleteAllBirthdays() async {
    final snapshots = await _birthdaysCollection.get();
    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }
  }


  Future<void> deleteBackedUpBirthday(String id) async {
    await _birthdaysCollection.doc(id).delete();
  }
}