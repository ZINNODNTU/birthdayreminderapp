import 'package:birthdayreminderapp/core/db/sync_status.dart';
import 'package:birthdayreminderapp/features/birthdays/data/birthday_firestore_mapper.dart';
import 'package:birthdayreminderapp/features/birthdays/data/birthday_remote_repository.dart';
import 'package:birthdayreminderapp/features/birthdays/data/birthday_repository.dart';
import 'package:birthdayreminderapp/features/birthdays/services/birthday_photo_service.dart';
import 'package:birthdayreminderapp/features/sync/sync_manager.dart';
import 'package:birthdayreminderapp/features/birthdays/domain/birthday_sync_copy.dart';
import 'package:birthdayreminderapp/models/birthday.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeLocalRepo implements BirthdayRepository {
  final Map<String, Birthday> rows = {};

  @override
  Future<List<Birthday>> getBirthdays() async => rows.values.toList();

  @override
  Future<List<Birthday>> getAllForSync() async => rows.values.toList();

  @override
  Future<Birthday?> getBirthday(String id) async => rows[id];

  @override
  Future<void> createBirthday(Birthday birthday) async {
    rows[birthday.id] = birthday;
  }

  @override
  Future<void> updateBirthday(Birthday birthday) async {
    rows[birthday.id] = birthday;
  }

  @override
  Future<void> upsertBirthday(Birthday birthday) async {
    rows[birthday.id] = birthday;
  }

  @override
  Future<void> deleteBirthday(String id) async {
    rows.remove(id);
  }

  @override
  Stream<List<Birthday>> watchBirthdays() async* {
    yield rows.values.toList();
  }
}

class _FakeRemoteRepo implements BirthdayRemoteRepository {
  final Map<String, Birthday> rows = {};

  /// Optional per-id photo payload to surface via getBirthdayRecords.
  final Map<String, CloudPhotoFields?> photos = {};
  Object? upsertError;
  int upsertCalls = 0;
  BirthdayCloudPhoto? lastUpsertedPhoto;

  BirthdayRemoteRepository makeCopy() {
    final copy =
        _FakeRemoteRepo()
          ..upsertError = upsertError
          ..rows.addAll(rows)
          ..photos.addAll(photos);
    return copy;
  }

  @override
  Future<List<FirestoreBirthdayRecord>> getBirthdayRecords(String uid) async {
    return rows.values
        .where((b) => b.ownerUid == uid)
        .map((b) => FirestoreBirthdayRecord(birthday: b, photo: photos[b.id]))
        .toList();
  }

  @override
  Future<void> upsertBirthday(
    String uid,
    Birthday birthday, {
    BirthdayCloudPhoto? photo,
    bool deletePhoto = false,
  }) async {
    upsertCalls++;
    lastUpsertedPhoto = photo;
    if (upsertError != null) throw upsertError!;
    rows[birthday.id] = birthday.copyWithForSync(ownerUid: uid);
  }

  /// Records every soft-delete request so tests can assert the sync
  /// path actually called [softDeleteBirthday] — never a hard delete.
  final List<String> softDeletedIds = [];

  @override
  Future<void> softDeleteBirthday(String uid, Birthday birthday) async {
    softDeletedIds.add(birthday.id);
    rows[birthday.id] = birthday.copyWithForSync(
      ownerUid: uid,
      deletedAt: birthday.deletedAt ?? DateTime.now(),
      updatedAt: birthday.updatedAt ?? DateTime.now(),
    );
  }

  @override
  Stream<List<FirestoreBirthdayRecord>> watchBirthdayRecords(
    String uid,
  ) async* {
    yield await getBirthdayRecords(uid);
  }
}

Birthday _row({
  required String id,
  SyncStatus status = SyncStatus.pendingUpload,
  String? ownerUid = 'user-a',
  DateTime? updatedAt,
  String? avatarBase64,
}) {
  return Birthday(
    id: id,
    name: 'Sample $id',
    solarBirthday: DateTime(2000, 1, 1),
    lunarBirthday: const LunarDateTime(day: 1, month: 1, year: 2000),
    calendarType: CalendarType.solar,
    remindBeforeDays: 1,
    remindTime: const TimeOfDay(hour: 9, minute: 0),
    isRecurringNotificationEnabled: true,
    repeatAnnually: true,
    avatarBase64: avatarBase64,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: updatedAt ?? DateTime(2024, 1, 1),
    syncStatus: status,
    ownerUid: ownerUid,
    schemaVersion: 1,
  );
}

SyncManager _make(
  _FakeLocalRepo local,
  _FakeRemoteRepo remote,
  StreamControllerMock auth, {
  String? uid,
  BirthdayPhotoService? photoService,
}) {
  return SyncManager(
    local: local,
    remote: remote,
    authGate: auth.stream,
    uidProvider: () => uid ?? '',
    photoService: photoService ?? const BirthdayPhotoService(),
  );
}

void main() {
  group('SyncManager', () {
    late _FakeLocalRepo local;
    late _FakeRemoteRepo remote;
    late StreamControllerMock auth;

    setUp(() {
      local = _FakeLocalRepo();
      remote = _FakeRemoteRepo();
      auth = StreamControllerMock();
    });

    test('syncAll is a no-op when not authenticated', () async {
      final mgr = _make(local, remote, auth);
      await mgr.syncAll();
      expect(remote.upsertCalls, 0);
      mgr.dispose();
    });

    test('pushPending moves pending rows to synced', () async {
      local.rows['a'] = _row(id: 'a', status: SyncStatus.pendingUpload);
      final mgr = _make(local, remote, auth, uid: 'user-a');
      await mgr.pushPending('user-a');
      expect(remote.upsertCalls, 1);
      expect(local.rows['a']!.syncStatus, SyncStatus.synced);
      mgr.dispose();
    });

    test('pushPending leaves failed uploads in pendingUpload', () async {
      local.rows['a'] = _row(id: 'a', status: SyncStatus.pendingUpload);
      remote.upsertError = Exception('boom');
      final mgr = _make(local, remote, auth, uid: 'user-a');
      await mgr.pushPending('user-a');
      expect(local.rows['a']!.syncStatus, SyncStatus.pendingUpload);
      mgr.dispose();
    });

    test('migrateLocalOnlyTo promotes and uploads', () async {
      local.rows['a'] = _row(
        id: 'a',
        status: SyncStatus.localOnly,
        ownerUid: null,
      );
      final mgr = _make(local, remote, auth, uid: 'user-a');
      final count = await mgr.migrateLocalOnlyTo('user-a');
      expect(count, 1);
      expect(local.rows['a']!.ownerUid, 'user-a');
      expect(remote.upsertCalls, 1);
      mgr.dispose();
    });

    test('conflict resolution: newer remote wins', () async {
      final old = _row(
        id: 'x',
        status: SyncStatus.synced,
        updatedAt: DateTime(2024, 1, 1),
      );
      local.rows['x'] = old;
      remote.rows['x'] = _row(
        id: 'x',
        status: SyncStatus.synced,
        updatedAt: DateTime(2024, 2, 2),
      );
      final mgr = _make(local, remote, auth, uid: 'user-a');
      await mgr.pullRemote('user-a');
      expect(local.rows['x']!.updatedAt, DateTime(2024, 2, 2));
      mgr.dispose();
    });

    test('user A never sees user B rows', () async {
      remote.rows['x'] = _row(id: 'x', ownerUid: 'user-b');
      final mgr = _make(local, remote, auth, uid: 'user-a');
      await mgr.pullRemote('user-a');
      expect(local.rows.containsKey('x'), false);
      mgr.dispose();
    });

    test(
      'pushPending sends no photo when local avatarBase64 is null',
      () async {
        local.rows['a'] = _row(id: 'a');
        final mgr = _make(local, remote, auth, uid: 'user-a');
        await mgr.pushPending('user-a');
        expect(remote.lastUpsertedPhoto, isNull);
        mgr.dispose();
      },
    );

    test(
      'pullRemote does NOT erase a local avatar when the cloud has none',
      () async {
        final localRow = _row(
          id: 'k',
          status: SyncStatus.synced,
          avatarBase64: 'LOCAL_KEEPS_THIS',
        );
        local.rows['k'] = localRow;
        // Remote has a NEWER timestamp but NO photo fields.
        remote.rows['k'] = _row(
          id: 'k',
          status: SyncStatus.synced,
          updatedAt: DateTime(2099, 1, 1),
        );
        final mgr = _make(local, remote, auth, uid: 'user-a');
        await mgr.pullRemote('user-a');
        expect(local.rows['k']!.updatedAt, DateTime(2099, 1, 1));
        expect(local.rows['k']!.avatarBase64, 'LOCAL_KEEPS_THIS');
        mgr.dispose();
      },
    );

    test(
      'pullRemote restores photoBase64 when local has none and cloud has photo',
      () async {
        local.rows['z'] = _row(id: 'z', status: SyncStatus.synced);
        remote.rows['z'] = _row(
          id: 'z',
          status: SyncStatus.synced,
          updatedAt: DateTime(2099, 1, 1),
        );
        remote.photos['z'] = CloudPhotoFields(
          base64: 'CLOUD_PHOTO_BASE64',
          mimeType: 'image/jpeg',
          size: 42,
          hash: 'deadbeef',
          updatedAt: DateTime(2024, 5, 6),
        );

        final mgr = _make(local, remote, auth, uid: 'user-a');
        await mgr.pullRemote('user-a');
        expect(local.rows['z']!.avatarBase64, 'CLOUD_PHOTO_BASE64');
        mgr.dispose();
      },
    );
  });
}

/// Trivial stream stand-in so [SyncManager] has a non-nullable `authGate`.
class StreamControllerMock {
  final controller = _Ctrl();
  Stream<dynamic> get stream => controller.stream;
  void add(dynamic value) => controller.add(value);
  void close() => controller.close();
}

class _Ctrl {
  final List<dynamic> _sink = [];
  Stream<dynamic> get stream {
    return Stream<dynamic>.fromIterable(_sink);
  }

  void add(dynamic value) => _sink.add(value);
  Future<void> close() async {}
}
