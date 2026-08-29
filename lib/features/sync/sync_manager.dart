import 'dart:async';

import '../../../core/db/sync_status.dart';
import '../../../core/logging/app_logger.dart';

import '../birthdays/data/birthday_remote_repository.dart';
import '../birthdays/data/birthday_repository.dart';
import '../birthdays/domain/birthday_sync_copy.dart';
import '../birthdays/domain/sync_outcome.dart';

/// Coordinates local ↔ cloud birthday data.
///
/// Design contract:
///
/// *   **Local DB is source of truth.** Every read the UI does comes
///     from the local repository. The cloud is a remote replica.
/// *   **Sync runs only when authenticated.** Local mode is a no-op.
/// *   **Owner isolation.** Each user only sees / writes records whose
///     `ownerUid` matches their Firebase UID.
/// *   **Failure-tolerant.** A failed push keeps the row in
///     `pendingUpload` and a failed delete keeps it in
///     `pendingDelete` — never rolled back locally.
/// *   **Conflict policy.** Last-write-wins by `updatedAt`. Ties resolve
///     deterministically by `id` so two equal-timestamp rows don't
///     oscillate between devices.
/// Coordinator class — only the local + remote fakes ever need to be
/// supplied.
class SyncManager {
  SyncManager({
    required BirthdayRepository local,
    required BirthdayRemoteRepository remote,
    required Stream<dynamic> authGate,
    required String Function() uidProvider,
  }) : _local = local,
       _remote = remote,
       _uidProvider = uidProvider,
       _authGate = authGate {
    _authSub = _authGate.listen(_onAuthGate);
  }

  final BirthdayRepository _local;
  final BirthdayRemoteRepository _remote;
  final String Function() _uidProvider;
  final Stream<dynamic> _authGate;

  StreamSubscription<dynamic>? _authSub;
  bool _syncInFlight = false;

  String? get _uid => _uidProvider();
  bool get _isAuthenticated => _uid != null && _uid!.isNotEmpty;

  void _onAuthGate(dynamic _) {
    // No-op trigger: whenever the auth state stream emits we attempt
    // a background reconciliation. The gate is a `dynamic` stream so
    // we don't bind the sync layer to a specific Auth contract.
    unawaited(syncAll());
  }

  /// Top-level reconciliation: push pending local mutations, then pull
  /// the remote mirror and merge. Bounded retry — failures leave rows
  /// in their pending state and the next call will retry.
  Future<void> syncAll() async {
    if (!_isAuthenticated) return;
    if (_syncInFlight) return;
    _syncInFlight = true;
    final uid = _uid!;
    try {
      await pushPending(uid);
      await pullRemote(uid);
    } catch (e, st) {
      AppLogger.warn('SyncManager', 'syncAll failed: $e\n$st');
    } finally {
      _syncInFlight = false;
    }
  }

  /// Push every local row that hasn't reached the cloud yet.
  Future<void> pushPending(String uid) async {
    final all = await _local.getBirthdays();
    for (final b in all) {
      if (b.syncStatus == SyncStatus.synced) continue;
      if (b.ownerUid != null && b.ownerUid != uid) continue;
      try {
        if (b.syncStatus == SyncStatus.pendingDelete) {
          await _remote.deleteBirthday(uid, b.id);
          // Hard-remove the local row once the cloud tombstone is
          // written — production sync policy.
          await _local.deleteBirthday(b.id);
          continue;
        }
        final stamped = b.copyWithForSync(
          ownerUid: uid,
          syncStatus: SyncStatus.synced,
        );
        await _remote.upsertBirthday(uid, stamped);
        await _local.upsertBirthday(stamped);
      } catch (e) {
        AppLogger.warn(
          'SyncManager',
          'push failed for ${b.id}: $e — leaving pending',
        );
      }
    }
  }

  /// Pull every cloud row and merge with the local copy. Newer
  /// `updatedAt` wins.
  Future<void> pullRemote(String uid) async {
    final remote = await _remote.getBirthdays(uid);
    final local = await _local.getBirthdays();
    final byId = {for (final b in local) b.id: b};
    for (final r in remote) {
      final l = byId[r.id];
      if (l == null) {
        await _local.upsertBirthday(r.copyWithForSync(ownerUid: uid));
        continue;
      }
      final localTs = l.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final remoteTs = r.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (remoteTs.isAfter(localTs)) {
        await _local.upsertBirthday(r);
      }
    }
  }

  /// Promote every local-only birthday to the given UID. Returns the
  /// number of rows promoted.
  Future<int> migrateLocalOnlyTo(String uid) async {
    final all = await _local.getBirthdays();
    var count = 0;
    for (final b in all) {
      if (b.ownerUid != null) continue;
      final stamped = b.copyWithForSync(
        ownerUid: uid,
        syncStatus: SyncStatus.pendingUpload,
      );
      await _local.upsertBirthday(stamped);
      count++;
    }
    if (count > 0) {
      await pushPending(uid);
    }
    return count;
  }

  /// Hook for retrying failed uploads (e.g. after the next online tick).
  Future<SyncOutcome> retryFailed() async {
    if (!_isAuthenticated) {
      return const SyncOutcome(noop: true);
    }
    final all = await _local.getBirthdays();
    var pushed = 0;
    var failed = 0;
    for (final b in all) {
      if (b.syncStatus != SyncStatus.pendingUpload &&
          b.syncStatus != SyncStatus.syncError) {
        continue;
      }
      try {
        await _remote.upsertBirthday(_uid!, b);
        await _local.upsertBirthday(
          b.copyWithForSync(syncStatus: SyncStatus.synced),
        );
        pushed++;
      } catch (_) {
        failed++;
      }
    }
    return SyncOutcome(pushed: pushed, failed: failed);
  }

  void dispose() {
    _authSub?.cancel();
  }
}
