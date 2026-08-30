import 'package:birthdayreminderapp/features/birthdays/data/birthday_firestore_mapper.dart';
import 'package:birthdayreminderapp/features/birthdays/data/birthday_remote_repository.dart';
import 'package:birthdayreminderapp/features/birthdays/domain/birthday_sync_copy.dart';
import 'package:birthdayreminderapp/models/birthday.dart';

/// In-memory [BirthdayRemoteRepository] for tests. Records every
/// interaction so tests can assert sync attempts.
class FakeBirthdayRemoteRepository implements BirthdayRemoteRepository {
  final List<Birthday> remoteBirthdays = [];
  int getBirthdaysCalls = 0;
  int upsertBirthdayCalls = 0;
  int deleteBirthdayCalls = 0;
  int watchBirthdayCalls = 0;

  /// Last upserted photo (if any).
  BirthdayCloudPhoto? lastUpsertedPhoto;

  /// Flags whether the caller wanted to delete the photo.
  bool lastUpsertedDeletePhoto = false;

  @override
  Future<List<FirestoreBirthdayRecord>> getBirthdayRecords(String uid) async {
    getBirthdaysCalls++;
    return remoteBirthdays
        .map((b) => FirestoreBirthdayRecord(birthday: b))
        .toList(growable: false);
  }

  @override
  Future<void> upsertBirthday(
    String uid,
    Birthday birthday, {
    BirthdayCloudPhoto? photo,
    bool deletePhoto = false,
  }) async {
    upsertBirthdayCalls++;
    lastUpsertedPhoto = photo;
    lastUpsertedDeletePhoto = deletePhoto;
    remoteBirthdays.removeWhere((b) => b.id == birthday.id);
    remoteBirthdays.add(birthday);
  }

  /// Tombstones written via [softDeleteBirthday]. Tests assert these
  /// without exposing the underlying Birthday object.
  final List<String> softDeletedIds = [];
  Object? softDeleteError;

  @override
  Future<void> softDeleteBirthday(String uid, Birthday birthday) async {
    if (softDeleteError != null) throw softDeleteError!;
    softDeletedIds.add(birthday.id);
    final idx = remoteBirthdays.indexWhere((b) => b.id == birthday.id);
    if (idx == -1) {
      remoteBirthdays.add(birthday);
    } else {
      // Preserve the original document body — only flip the deletion
      // state. The original name / photoBase64 / reminder etc. are
      // untouched.
      final merged = remoteBirthdays[idx].copyWithForSync(
        deletedAt: birthday.deletedAt ?? DateTime.now(),
        updatedAt: birthday.updatedAt ?? DateTime.now(),
      );
      remoteBirthdays[idx] = merged;
    }
  }

  @override
  Stream<List<FirestoreBirthdayRecord>> watchBirthdayRecords(
    String uid,
  ) async* {
    watchBirthdayCalls++;
    yield remoteBirthdays
        .map((b) => FirestoreBirthdayRecord(birthday: b))
        .toList(growable: false);
  }
}
