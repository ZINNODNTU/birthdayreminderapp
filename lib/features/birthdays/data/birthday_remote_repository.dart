import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/birthday.dart';
import 'birthday_firestore_mapper.dart';

/// Single source of truth for the Firestore birthday tree.
///
/// All cloud reads and writes must go through this interface — the UI
/// must never reach for [FirebaseFirestore] directly. The only path is
/// `/users/{uid}/birthdays/{id}`. Legacy `/birthdays/{id}` is denied at
/// the rules level.
abstract class BirthdayRemoteRepository {
  /// Fetch every birthday document for [uid]. The returned records
  /// carry an optional [FirestoreBirthdayRecord.photo] so the caller
  /// can decide whether to restore the image to local storage.
  Future<List<FirestoreBirthdayRecord>> getBirthdayRecords(String uid);

  /// Persist [birthday] to Firestore. When [photo] is non-null the
  /// cloud fields are written; when [deletePhoto] is true the
  /// existing cloud fields are explicitly removed via
  /// [FieldValue.delete]. When both are null/false the photo fields
  /// are left untouched on the server.
  Future<void> upsertBirthday(
    String uid,
    Birthday birthday, {
    BirthdayCloudPhoto? photo,
    bool deletePhoto = false,
  });

  /// Mark [birthday] as soft-deleted on the server. The original
  /// document body — including `name`, `photoBase64`, reminder config,
  /// etc. — is preserved verbatim. Only `isDeleted`, `deletedAt`,
  /// `updatedAt` are flipped.
  Future<void> softDeleteBirthday(String uid, Birthday birthday);

  Stream<List<FirestoreBirthdayRecord>> watchBirthdayRecords(String uid);
}

/// Production implementation backed by [FirebaseFirestore].
class FirestoreBirthdayRemoteRepository implements BirthdayRemoteRepository {
  FirestoreBirthdayRemoteRepository({
    FirebaseFirestore? firestore,
    BirthdayFirestoreMapper? mapper,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _mapper = mapper ?? const BirthdayFirestoreMapper();

  final FirebaseFirestore _db;
  final BirthdayFirestoreMapper _mapper;

  CollectionReference<Map<String, dynamic>> _collection(String uid) {
    return _db.collection('users').doc(uid).collection('birthdays');
  }

  @override
  Future<List<FirestoreBirthdayRecord>> getBirthdayRecords(String uid) async {
    if (uid.isEmpty) return const [];
    final snap = await _collection(uid).get();
    return snap.docs
        .map(_mapper.fromFirestore)
        .whereType<FirestoreBirthdayRecord>()
        .toList(growable: false);
  }

  @override
  Future<void> upsertBirthday(
    String uid,
    Birthday birthday, {
    BirthdayCloudPhoto? photo,
    bool deletePhoto = false,
  }) {
    return _collection(uid)
        .doc(birthday.id)
        .set(
          _mapper.toFirestore(birthday, photo: photo, deletePhoto: deletePhoto),
        );
  }

  /// Mark [birthday] as soft-deleted on the server. The original
  /// document body — including `name`, `photoBase64`, reminder config,
  /// etc. — is preserved verbatim. Only `isDeleted`, `deletedAt`,
  /// `updatedAt` are flipped.
  @override
  Future<void> softDeleteBirthday(String uid, Birthday birthday) async {
    final now = FieldValue.serverTimestamp();
    await _collection(uid).doc(birthday.id).set({
      'isDeleted': true,
      'deletedAt': Timestamp.fromDate(birthday.deletedAt ?? DateTime.now()),
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  @override
  Stream<List<FirestoreBirthdayRecord>> watchBirthdayRecords(String uid) {
    if (uid.isEmpty) return const Stream.empty();
    return _collection(uid).snapshots().map(
      (snap) => snap.docs
          .map(_mapper.fromFirestore)
          .whereType<FirestoreBirthdayRecord>()
          .toList(growable: false),
    );
  }
}
