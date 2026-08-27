/// Status of a birthday record with respect to remote sync.
///
/// Local-only records are never touched by cloud. Records owned by a
/// signed-in user can move through the other states during Phase 5 (sync).
enum SyncStatus {
  localOnly,
  pendingUpload,
  synced,
  pendingDelete,
  syncError;

  String get storageValue => switch (this) {
    SyncStatus.localOnly => 'localOnly',
    SyncStatus.pendingUpload => 'pendingUpload',
    SyncStatus.synced => 'synced',
    SyncStatus.pendingDelete => 'pendingDelete',
    SyncStatus.syncError => 'syncError',
  };

  static SyncStatus fromStorage(String? value) {
    switch (value) {
      case 'pendingUpload':
        return SyncStatus.pendingUpload;
      case 'synced':
        return SyncStatus.synced;
      case 'pendingDelete':
        return SyncStatus.pendingDelete;
      case 'syncError':
        return SyncStatus.syncError;
      case 'localOnly':
      default:
        return SyncStatus.localOnly;
    }
  }
}
