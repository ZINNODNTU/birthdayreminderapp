import 'package:birthdayreminderapp/core/db/sync_status.dart';
import 'package:birthdayreminderapp/features/birthdays/data/birthday_remote_repository.dart';
import 'package:birthdayreminderapp/features/birthdays/data/birthday_repository.dart';
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
  Object? upsertError;
  int upsertCalls = 0;

  @override
  Future<List<Birthday>> getBirthdays(String uid) async =>
      rows.values.where((b) => b.ownerUid == uid).toList();

  @override
  Future<void> upsertBirthday(String uid, Birthday birthday) async {
    upsertCalls++;
    if (upsertError != null) throw upsertError!;
    rows[birthday.id] = birthday.copyWithForSync(ownerUid: uid);
  }

  @override
  Future<void> deleteBirthday(String uid, String birthdayId) async {
    rows.remove(birthdayId);
  }

  @override
  Stream<List<Birthday>> watchBirthdays(String uid) async* {
    yield await getBirthdays(uid);
  }
}

Birthday _row({
  required String id,
  SyncStatus status = SyncStatus.pendingUpload,
  String? ownerUid = 'user-a',
  DateTime? updatedAt,
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
    note: null,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: updatedAt ?? DateTime(2024, 1, 1),
    syncStatus: status,
    ownerUid: ownerUid,
    schemaVersion: 1,
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
      final mgr = SyncManager(
        local: local,
        remote: remote,
        authGate: auth.stream,
        uidProvider: () => '',
      );
      await mgr.syncAll();
      expect(remote.upsertCalls, 0);
      mgr.dispose();
    });

    test('pushPending moves pending rows to synced', () async {
      local.rows['a'] = _row(id: 'a', status: SyncStatus.pendingUpload);
      final mgr = SyncManager(
        local: local,
        remote: remote,
        authGate: auth.stream,
        uidProvider: () => 'user-a',
      );
      await mgr.pushPending('user-a');
      expect(remote.upsertCalls, 1);
      expect(local.rows['a']!.syncStatus, SyncStatus.synced);
      mgr.dispose();
    });

    test('pushPending leaves failed uploads in pendingUpload', () async {
      local.rows['a'] = _row(id: 'a', status: SyncStatus.pendingUpload);
      remote.upsertError = Exception('boom');
      final mgr = SyncManager(
        local: local,
        remote: remote,
        authGate: auth.stream,
        uidProvider: () => 'user-a',
      );
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
      final mgr = SyncManager(
        local: local,
        remote: remote,
        authGate: auth.stream,
        uidProvider: () => 'user-a',
      );
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
      final mgr = SyncManager(
        local: local,
        remote: remote,
        authGate: auth.stream,
        uidProvider: () => 'user-a',
      );
      await mgr.pullRemote('user-a');
      expect(local.rows['x']!.updatedAt, DateTime(2024, 2, 2));
      mgr.dispose();
    });

    test('user A never sees user B rows', () async {
      remote.rows['x'] = _row(id: 'x', ownerUid: 'user-b');
      final mgr = SyncManager(
        local: local,
        remote: remote,
        authGate: auth.stream,
        uidProvider: () => 'user-a',
      );
      await mgr.pullRemote('user-a');
      expect(local.rows.containsKey('x'), false);
      mgr.dispose();
    });
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
