import '../../../models/birthday.dart';

/// Abstraction over birthday storage. UI code must depend on this, not on
/// SQLite or Firestore directly. The local implementation is provided in
/// Phase 2; the cloud-backed implementation lands in Phase 5.
abstract interface class BirthdayRepository {
  Future<List<Birthday>> getBirthdays();

  /// All rows including tombstones. Used exclusively by SyncManager
  /// so it can find `pendingDelete` rows without exposing them in UI.
  Future<List<Birthday>> getAllForSync();

  Future<Birthday?> getBirthday(String id);
  Future<void> createBirthday(Birthday birthday);
  Future<void> updateBirthday(Birthday birthday);

  /// Create-or-update used by SyncManager — never roll back a row that
  /// already exists, even if the caller supplied different metadata.
  Future<void> upsertBirthday(Birthday birthday);

  /// Reserved for future maintenance / purge tooling. The normal UI
  /// delete flow must NEVER call this — it is documented as a
  /// destructive operation that removes the row from SQLite.
  Future<void> deleteBirthday(String id);

  /// Emits the current list after any mutation. The default implementation
  /// is a fire-and-forget re-emit; concrete classes may override with a
  /// proper stream backed by a query observer.
  Stream<List<Birthday>> watchBirthdays() async* {
    yield await getBirthdays();
  }
}

abstract interface class TransactionalBirthdayRepository {
  Future<void> restoreBirthdaysTransactionally(
    List<Birthday> birthdays, {
    required bool replace,
  });
}
