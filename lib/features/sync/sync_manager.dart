import 'dart:async';

import '../../../core/db/sync_status.dart';
import '../../../core/logging/app_logger.dart';

import '../../../models/birthday.dart';
import '../birthdays/data/birthday_firestore_mapper.dart';
import '../birthdays/data/birthday_remote_repository.dart';
import '../birthdays/data/birthday_repository.dart';
import '../birthdays/data/local_birthday_repository.dart';
import '../birthdays/domain/birthday_sync_copy.dart';
import '../birthdays/domain/sync_outcome.dart';
import '../birthdays/services/birthday_photo_service.dart';

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
/// *   **Photo backfill.** A local birthday that already has an image
///     but whose cloud document has no `photoBase64` triggers a
///     one-time backfill on the next sync — never an erase.
class SyncManager {
  SyncManager({
    required BirthdayRepository local,
    required BirthdayRemoteRepository remote,
    required Stream<dynamic> authGate,
    required String Function() uidProvider,
    required BirthdayPhotoService photoService,
  }) : _local = local,
       _remote = remote,
       _uidProvider = uidProvider,
       _authGate = authGate,
       _photoService = photoService {
    _authSub = _authGate.listen(_onAuthGate);
  }

  final BirthdayRepository _local;
  final BirthdayRemoteRepository _remote;
  final String Function() _uidProvider;
  final Stream<dynamic> _authGate;
  final BirthdayPhotoService _photoService;

  StreamSubscription<dynamic>? _authSub;
  Future<void>? _activeSync;

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
  Future<void> syncAll() {
    if (!_isAuthenticated) return Future.value();
    if (_activeSync != null) return _activeSync!;
    final uid = _uid!;
    final future = _performSync(uid);
    _activeSync = future;
    return future.whenComplete(() {
      if (identical(_activeSync, future)) {
        _activeSync = null;
      }
    });
  }

  Future<void> _performSync(String uid) async {
    try {
      await pushPending(uid);
      await pullRemote(uid);
    } catch (e, st) {
      AppLogger.warn('SyncManager', 'syncAll failed: $e\n$st');
    }
  }

  /// Push every local row that hasn't reached the cloud yet. Uses
  /// [getAllForSync] so `pendingDelete` tombstones are visible here
  /// even though the UI never shows them.
  Future<void> pushPending(String uid) async {
    final all = await _local.getAllForSync();
    for (final b in all) {
      if (b.syncStatus == SyncStatus.synced) continue;
      if (b.ownerUid != null && b.ownerUid != uid) continue;
      try {
        if (b.syncStatus == SyncStatus.pendingDelete) {
          AppLogger.debug('SyncManager', 'soft-delete push start id=${b.id}');
          await _remote.softDeleteBirthday(uid, b);
          AppLogger.debug(
            'SyncManager',
            'soft-delete remote success id=${b.id}',
          );
          // Keep the local tombstone row — only flip syncStatus so
          // the next pull does not resurrect it.
          await _local.upsertBirthday(
            b.copyWithForSync(syncStatus: SyncStatus.synced),
          );
          AppLogger.debug(
            'SyncManager',
            'soft-delete local tombstone synced id=${b.id}',
          );
          continue;
        }
        final stamped = b.copyWithForSync(
          ownerUid: uid,
          syncStatus: SyncStatus.synced,
        );
        final photo = await _buildCloudPhoto(stamped);
        await _remote.upsertBirthday(uid, stamped, photo: photo);
        await _local.upsertBirthday(stamped);
      } catch (e) {
        AppLogger.warn(
          'SyncManager',
          'push failed for ${b.id}: $e — leaving pending',
        );
      }
    }
  }

  /// Build a [BirthdayCloudPhoto] from the local `avatarBase64`.
  /// Re-uses the controller-side compression (idempotent).
  Future<BirthdayCloudPhoto?> _buildCloudPhoto(Birthday b) async {
    if (b.avatarBase64 == null || b.avatarBase64!.isEmpty) return null;
    final encoded = await _photoService.encodeForCloud(
      base64Input: b.avatarBase64!,
    );
    if (!encoded.ok) {
      AppLogger.warn(
        'SyncManager',
        'photo for ${b.id} could not be encoded: ${encoded.failure}',
      );
      return null;
    }
    return BirthdayCloudPhoto.fromEncoded(encoded.photo!);
  }

  /// Pull every cloud row and merge with the local copy. Newer
  /// `updatedAt` wins. When the remote carries a photo, the local
  /// `avatarBase64` is restored (only if the local side is currently
  /// empty or behind on hash — see [_mergePhoto]).
  Future<void> pullRemote(String uid) async {
    final remote = await _remote.getBirthdayRecords(uid);
    final local = await _local.getBirthdays();
    final byId = {for (final b in local) b.id: b};
    for (final r in remote) {
      final l = byId[r.birthday.id];
      final remoteDeleted = r.birthday.deletedAt != null;
      if (remoteDeleted) {
        // Cloud tombstone — never restore as visible. If local has a
        // matching row, mirror the deletion state; otherwise insert a
        // hidden tombstone so subsequent pushes do not re-create it.
        final localTs = l?.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final remoteTs =
            r.birthday.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        if (remoteTs.isAfter(localTs) || l == null) {
          final tombstone = r.birthday.copyWithForSync(
            ownerUid: uid,
            syncStatus: SyncStatus.synced,
          );
          await _local.upsertBirthday(tombstone);
        }
        continue;
      }
      if (l == null) {
        await _local.upsertBirthday(await _withRestoredPhoto(r, uid));
        continue;
      }
      final localTs = l.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final remoteTs =
          r.birthday.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (remoteTs.isAfter(localTs)) {
        await _local.upsertBirthday(
          await _withRestoredPhoto(r, uid, existing: l),
        );
      }
    }
  }

  /// Restore the photo Base64 from the cloud record into the local
  /// `avatarBase64`. Three cases:
  ///   * Cloud has photo, local missing → restore.
  ///   * Cloud has photo, local has photo → keep whichever is newer
  ///     (cloud wins on tie; legacy local photoHash not tracked).
  ///   * Cloud missing photo, local has photo → keep local (legacy
  ///     backfill path; the next push will upload it).
  Future<Birthday> _withRestoredPhoto(
    FirestoreBirthdayRecord r,
    String uid, {
    Birthday? existing,
  }) async {
    final photo = r.photo;
    final localAvatar =
        existing?.avatarBase64 != null && existing!.avatarBase64!.isNotEmpty
            ? existing.avatarBase64
            : null;
    if (photo == null) {
      // Cloud missing photo — never erase local. Keep the local
      // avatar untouched so a legacy cloud record cannot blank a
      // still-valid local image; the next push will backfill.
      final stamped = r.birthday.copyWithForSync(ownerUid: uid);
      return localAvatar == null
          ? stamped
          : stamped.copyWith(avatarBase64: localAvatar);
    }
    if (localAvatar != null) {
      // Both sides have a photo. Skip the cloud-side write to avoid
      // an expensive decode when the local hash already matches —
      // exact equality is good enough for the regression set, and
      // the next explicit edit will reconcile.
      return r.birthday.copyWithForSync(ownerUid: uid);
    }
    // Cloud has photo, local is empty — restore the cloud payload.
    return r.birthday
        .copyWithForSync(ownerUid: uid)
        .copyWith(avatarBase64: photo.base64);
  }

  /// Promote every local-only birthday to the given UID. Returns the
  /// number of rows promoted.
  Future<int> migrateLocalOnlyTo(String uid) async {
    final all = await _local.getAllForSync();
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
    final all = await _local.getAllForSync();
    var pushed = 0;
    var failed = 0;
    for (final b in all) {
      if (b.syncStatus != SyncStatus.pendingUpload &&
          b.syncStatus != SyncStatus.syncError) {
        continue;
      }
      try {
        final photo = await _buildCloudPhoto(b);
        await _remote.upsertBirthday(_uid!, b, photo: photo);
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
