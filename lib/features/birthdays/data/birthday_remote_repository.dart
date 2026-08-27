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
  Future<List<Birthday>> getBirthdays(String uid);

  Future<void> upsertBirthday(String uid, Birthday birthday);

  Future<void> deleteBirthday(String uid, String birthdayId);

  Stream<List<Birthday>> watchBirthdays(String uid);
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
  Future<List<Birthday>> getBirthdays(String uid) async {
    if (uid.isEmpty) return const [];
    final snap = await _collection(uid).get();
    return snap.docs
        .map(_mapper.fromFirestore)
        .whereType<Birthday>()
        .toList(growable: false);
  }

  @override
  Future<void> upsertBirthday(String uid, Birthday birthday) {
    return _collection(uid).doc(birthday.id).set(_mapper.toFirestore(birthday));
  }

  @override
  Future<void> deleteBirthday(String uid, String birthdayId) {
    // Soft-delete mirrors the SQLite convention: the document stays,
    // we just stamp `deletedAt`. Hard delete is reserved for the
    // future cleanup pass once cloud sync ships.
    final now = DateTime.now();
    final tombstone = {
      'id': birthdayId,
      'name': '',
      'calendarType': CalendarType.solar.name,
      'solarBirthday': Timestamp.fromDate(now),
      'lunar': null,
      'note': null,
      'reminder': const {
        'enabled': false,
        'daysBefore': 0,
        'hour': 0,
        'minute': 0,
        'repeatAnnually': false,
      },
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'deletedAt': Timestamp.fromDate(now),
      'schemaVersion': BirthdayFirestoreMapper.schemaVersion,
    };
    return _collection(uid).doc(birthdayId).set(tombstone);
  }

  @override
  Stream<List<Birthday>> watchBirthdays(String uid) {
    if (uid.isEmpty) return const Stream.empty();
    return _collection(uid).snapshots().map(
      (snap) => snap.docs
          .map(_mapper.fromFirestore)
          .whereType<Birthday>()
          .toList(growable: false),
    );
  }
}
