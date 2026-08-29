import '../../../models/birthday.dart';

/// Abstraction over birthday storage. UI code must depend on this, not on
/// SQLite or Firestore directly. The local implementation is provided in
/// Phase 2; the cloud-backed implementation lands in Phase 5.
abstract interface class BirthdayRepository {
  Future<List<Birthday>> getBirthdays();
  Future<Birthday?> getBirthday(String id);
  Future<void> createBirthday(Birthday birthday);
  Future<void> updateBirthday(Birthday birthday);

  /// Create-or-update used by SyncManager — never roll back a row that
  /// already exists, even if the caller supplied different metadata.
  Future<void> upsertBirthday(Birthday birthday);

  Future<void> deleteBirthday(String id);

  /// Emits the current list after any mutation. The default implementation
  /// is a fire-and-forget re-emit; concrete classes may override with a
  /// proper stream backed by a query observer.
  Stream<List<Birthday>> watchBirthdays() async* {
    yield await getBirthdays();
  }
}
