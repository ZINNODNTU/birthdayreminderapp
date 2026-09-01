import 'package:birthdayreminderapp/controllers/birthday_controller.dart';
import 'package:birthdayreminderapp/core/auth/auth_repository.dart';
import 'package:birthdayreminderapp/core/db/sync_status.dart';
import 'package:birthdayreminderapp/features/birthdays/data/birthday_firestore_mapper.dart';
import 'package:birthdayreminderapp/features/birthdays/data/birthday_remote_repository.dart';
import 'package:birthdayreminderapp/features/birthdays/data/birthday_repository.dart';
import 'package:birthdayreminderapp/features/birthdays/domain/default_birthday_engine.dart';
import 'package:birthdayreminderapp/features/birthdays/domain/lunar_calendar_service.dart';
import 'package:birthdayreminderapp/features/birthdays/services/birthday_photo_service.dart';
import 'package:birthdayreminderapp/features/birthdays/domain/birthday_sync_copy.dart';

import 'package:birthdayreminderapp/features/reminders/services/reminder_scheduler.dart';
import 'package:birthdayreminderapp/features/sync/sync_manager.dart';
import 'package:birthdayreminderapp/models/birthday.dart';
import 'package:birthdayreminderapp/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_auth_repository.dart' show FakeUser;

class _FakeAuthRepo implements AuthRepository {
  _FakeAuthRepo({this.user});
  User? user;
  @override
  User? get currentUser => user;
  @override
  Stream<User?> get authStateChanges => const Stream.empty();
  @override
  Future<User?> signInWithGoogle() async => user;
  @override
  Future<void> signOut() async {
    user = null;
  }
}

class _FakeLocalRepo implements BirthdayRepository {
  final Map<String, Birthday> rows = {};
  final List<String> hardDeletedIds = [];

  @override
  Future<List<Birthday>> getBirthdays() async {
    return rows.values.where((b) => b.deletedAt == null).toList();
  }

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
    hardDeletedIds.add(id);
    rows.remove(id);
  }

  @override
  Stream<List<Birthday>> watchBirthdays() async* {
    yield rows.values.toList();
  }
}

class _FakeRemoteRepo implements BirthdayRemoteRepository {
  final List<String> softDeletedIds = [];
  Object? softDeleteError;
  int upsertCalls = 0;
  int hardDeleteCalls = 0;

  @override
  Future<List<FirestoreBirthdayRecord>> getBirthdayRecords(String uid) async {
    return const [];
  }

  @override
  Future<void> upsertBirthday(
    String uid,
    Birthday birthday, {
    BirthdayCloudPhoto? photo,
    bool deletePhoto = false,
  }) async {
    upsertCalls++;
  }

  @override
  Future<void> softDeleteBirthday(String uid, Birthday birthday) async {
    if (softDeleteError != null) throw softDeleteError!;
    softDeletedIds.add(birthday.id);
  }

  @override
  Stream<List<FirestoreBirthdayRecord>> watchBirthdayRecords(
    String uid,
  ) async* {
    yield const [];
  }
}

class _FakeReminderScheduler implements ReminderScheduler {
  final List<String> cancelCalls = [];
  bool shouldThrow = false;

  @override
  Future<void> cancelAllFor(String birthdayId) async {
    if (shouldThrow) throw Exception('cancel failed');
    cancelCalls.add(birthdayId);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubSyncManager implements SyncManager {
  int calls = 0;
  @override
  Future<void> syncAll({void Function(int, int)? onProgress}) async {
    calls++;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Birthday _sample(String id, {String name = 'DELETE TEST ONE'}) => Birthday(
  id: id,
  name: name,
  solarBirthday: DateTime(2000, 1, 1),
  lunarBirthday: const LunarDateTime(day: 1, month: 1, year: 2000),
  calendarType: CalendarType.solar,
  remindBeforeDays: 1,
  remindTime: const TimeOfDay(hour: 9, minute: 0),
  isRecurringNotificationEnabled: true,
  repeatAnnually: true,
  schemaVersion: 1,
  createdAt: DateTime(2024, 1, 1),
  updatedAt: DateTime(2024, 1, 1),
  syncStatus: SyncStatus.synced,
  ownerUid: null,
);

User _stubUser(String uid) {
  return FakeUser('test@example.com', uid: uid);
}

BirthdayController _buildController({
  required _FakeLocalRepo local,
  required _FakeAuthRepo auth,
  required _FakeReminderScheduler scheduler,
  _StubSyncManager? sync,
}) {
  return BirthdayController(
    repository: local,
    reminderScheduler: scheduler,
    notificationService: NotificationService(),
    engine: const DefaultBirthdayEngine(LunarCalendarService()),
    authRepository: auth,
    syncManager: sync ?? _StubSyncManager(),
    photoService: const BirthdayPhotoService(),
  );
}

void main() {
  group('BirthdayController.deleteBirthday (soft-delete)', () {
    test('local mode: tombstone kept; no hard delete', () async {
      final local = _FakeLocalRepo();
      final scheduler = _FakeReminderScheduler();
      final auth = _FakeAuthRepo();
      final controller = _buildController(
        local: local,
        auth: auth,
        scheduler: scheduler,
      );
      await local.createBirthday(_sample('a'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final ok = await controller.deleteBirthday('a');
      expect(ok, true);
      expect(scheduler.cancelCalls, contains('a'));
      expect(local.hardDeletedIds, isEmpty);
      expect(local.rows.containsKey('a'), true);
      expect(local.rows['a']!.deletedAt, isNotNull);
      expect(local.rows['a']!.syncStatus, SyncStatus.localOnly);
    });

    test('local mode: tombstone hidden from getBirthdays()', () async {
      final local = _FakeLocalRepo();
      final scheduler = _FakeReminderScheduler();
      final auth = _FakeAuthRepo();
      final controller = _buildController(
        local: local,
        auth: auth,
        scheduler: scheduler,
      );
      await local.createBirthday(_sample('a'));

      await controller.deleteBirthday('a');
      final visible = await local.getBirthdays();
      expect(visible, isEmpty);
      final allForSync = await local.getAllForSync();
      expect(allForSync.where((b) => b.id == 'a').length, 1);
    });

    test('authenticated: tombstone written; sync NEVER triggered', () async {
      final local = _FakeLocalRepo();
      final auth = _FakeAuthRepo(user: _stubUser('user-a'));
      final scheduler = _FakeReminderScheduler();
      final sync = _StubSyncManager();
      final controller = _buildController(
        local: local,
        auth: auth,
        scheduler: scheduler,
        sync: sync,
      );
      // Drain the bootstrap sync so it does not contaminate the
      // assertion below.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      sync.calls = 0;
      await local.upsertBirthday(
        _sample('k')
            .copyWithForSync(ownerUid: 'user-a', syncStatus: SyncStatus.synced),
      );

      final ok = await controller.deleteBirthday('k');
      expect(ok, true);
      expect(sync.calls, 0);
      expect(local.rows['k']!.syncStatus, SyncStatus.pendingDelete);
      expect(local.rows['k']!.deletedAt, isNotNull);
      expect(scheduler.cancelCalls, contains('k'));
    });

    test('authenticated: pushPending soft-deletes + keeps tombstone', () async {
      final local = _FakeLocalRepo();
      final remote = _FakeRemoteRepo();
      final sync = SyncManager(
        local: local,
        remote: remote,
        authGate: const Stream.empty(),
        uidProvider: () => 'user-a',
        photoService: const BirthdayPhotoService(),
      );
      await local.upsertBirthday(
        _sample('x').copyWithForSync(
          ownerUid: 'user-a',
          syncStatus: SyncStatus.pendingDelete,
          deletedAt: DateTime.now(),
        ),
      );
      await sync.pushPending('user-a');
      expect(remote.softDeletedIds, contains('x'));
      expect(remote.hardDeleteCalls, 0);
      expect(local.hardDeletedIds, isEmpty);
      expect(local.rows['x']!.syncStatus, SyncStatus.synced);
      expect(local.rows['x']!.deletedAt, isNotNull);
    });

    test(
      'authenticated: remote soft-delete fails → tombstone stays pendingDelete',
      () async {
        final local = _FakeLocalRepo();
        final remote = _FakeRemoteRepo()
          ..softDeleteError = Exception('network');
        final sync = SyncManager(
          local: local,
          remote: remote,
          authGate: const Stream.empty(),
          uidProvider: () => 'user-a',
          photoService: const BirthdayPhotoService(),
        );
        await local.upsertBirthday(
          _sample('z').copyWithForSync(
            ownerUid: 'user-a',
            syncStatus: SyncStatus.pendingDelete,
            deletedAt: DateTime.now(),
          ),
        );
        await sync.pushPending('user-a');
        expect(remote.softDeletedIds, isEmpty);
        expect(local.rows['z']!.syncStatus, SyncStatus.pendingDelete);
        expect(local.rows['z']!.deletedAt, isNotNull);
      },
    );

    test(
      'authenticated: unknown id → returns false (no cancel, no tombstone)',
      () async {
        final local = _FakeLocalRepo();
        final auth = _FakeAuthRepo(user: _stubUser('user-a'));
        final scheduler = _FakeReminderScheduler();
        final controller = _buildController(
          local: local,
          auth: auth,
          scheduler: scheduler,
        );
        final ok = await controller.deleteBirthday('unknown-id');
        expect(ok, false);
        expect(scheduler.cancelCalls, isEmpty);
      },
    );

    test(
      'authenticated: failed reminder cancel does not block tombstone',
      () async {
        final local = _FakeLocalRepo();
        final auth = _FakeAuthRepo(user: _stubUser('user-a'));
        final scheduler = _FakeReminderScheduler()..shouldThrow = true;
        await local.upsertBirthday(
          _sample(
            'resilient',
          ).copyWithForSync(ownerUid: 'user-a', syncStatus: SyncStatus.synced),
        );
        final controller = _buildController(
          local: local,
          auth: auth,
          scheduler: scheduler,
        );
        final ok = await controller.deleteBirthday('resilient');
        expect(ok, true);
        expect(local.rows['resilient']!.syncStatus, SyncStatus.pendingDelete);
        expect(local.rows['resilient']!.deletedAt, isNotNull);
      },
    );
  });
}
