import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/auth/auth_repository.dart';
import '../features/birthdays/data/birthday_repository.dart';
import '../core/db/sync_status.dart';
import '../features/birthdays/domain/birthday_sync_copy.dart';
import '../features/birthdays/domain/birthday_engine.dart';
import '../features/sync/sync_manager.dart';
import '../services/notification_service.dart';
import '../features/reminders/services/reminder_scheduler.dart';
import '../models/birthday.dart';

/// Owns the in-memory list of birthdays and forwards mutations to the
/// repository, the reminder scheduler, and — when the user is
/// authenticated — [SyncManager] for cloud replication.
class BirthdayController with ChangeNotifier {
  BirthdayController({
    required BirthdayRepository repository,
    required ReminderScheduler reminderScheduler,
    required NotificationService notificationService,
    required BirthdayEngine engine,
    AuthRepository? authRepository,
    SyncManager? syncManager,
  }) : _repository = repository,
       _scheduler = reminderScheduler,
       _notificationService = notificationService,
       _engine = engine,
       _authRepository = authRepository,
       _syncManager = syncManager {
    loadBirthdays();
  }

  final BirthdayRepository _repository;
  final ReminderScheduler _scheduler;
  final NotificationService _notificationService;
  final BirthdayEngine _engine;
  final AuthRepository? _authRepository;
  final SyncManager? _syncManager;

  List<Birthday> _birthdays = [];
  bool _disposed = false;

  List<Birthday> get birthdays => _birthdays;

  List<Birthday> sortedByUpcoming({DateTime? from}) {
    final list = [..._birthdays];
    list.sort(
      (a, b) => _engine
          .daysUntilNextBirthday(a, from: from)
          .compareTo(_engine.daysUntilNextBirthday(b, from: from)),
    );
    return list;
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  bool get _isAuthenticated =>
      _authRepository?.currentUser != null &&
      _authRepository!.currentUser!.uid.isNotEmpty;

  /// Wrap a row with the correct sync metadata given the current
  /// authentication state. Local-only rows keep
  /// `syncStatus: localOnly`; authenticated rows become
  /// `pendingUpload`.
  Birthday _stampForSync(Birthday b) {
    final now = DateTime.now();
    if (!_isAuthenticated) {
      return b.copyWithForSync(
        syncStatus: SyncStatus.localOnly,
        updatedAt: now,
      );
    }
    final uid = _authRepository!.currentUser!.uid;
    return b.copyWithForSync(
      ownerUid: uid,
      syncStatus: SyncStatus.pendingUpload,
      updatedAt: now,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> loadBirthdays() async {
    _birthdays = await _repository.getBirthdays();
    _safeNotify();
    // Fire-and-forget background reconciliation after every load.
    if (_isAuthenticated) {
      unawaited(_syncManager?.syncAll());
    }
  }

  Future<void> addBirthday(Birthday birthday) async {
    final stamped = _stampForSync(birthday);
    await _repository.createBirthday(stamped);
    _birthdays = await _repository.getBirthdays();
    _safeNotify();
    await _scheduler.scheduleNext(stamped);
    if (_isAuthenticated) {
      unawaited(_syncManager?.syncAll());
    }
  }

  Future<void> updateBirthday(Birthday birthday) async {
    final stamped = _stampForSync(birthday);
    await _repository.updateBirthday(stamped);
    final index = _birthdays.indexWhere((b) => b.id == stamped.id);
    if (index != -1) {
      _birthdays[index] = stamped;
      _safeNotify();
    }
    await _scheduler.scheduleNext(stamped);
    if (_isAuthenticated) {
      unawaited(_syncManager?.syncAll());
    }
  }

  Future<void> deleteBirthday(String id) async {
    await _scheduler.cancelAllFor(id);
    if (_isAuthenticated) {
      // Soft-delete: stamp deletedAt + pendingDelete, keep the row
      // until SyncManager confirms the cloud tombstone.
      final existing = _birthdays.firstWhere((b) => b.id == id);
      final stamped = existing.copyWithForSync(
        syncStatus: SyncStatus.pendingDelete,
        updatedAt: DateTime.now(),
      );
      await _repository.upsertBirthday(stamped);
      unawaited(_syncManager?.syncAll());
    } else {
      await _repository.deleteBirthday(id);
    }
    _birthdays = await _repository.getBirthdays();
    _safeNotify();
  }

  Future<void> testNotification(Birthday birthday) async {
    final days = _engine.daysUntilNextBirthday(birthday);
    await _notificationService.showTestNotification(
      title: 'Thông báo thử',
      body: 'Sinh nhật của ${birthday.name} còn $days ngày nữa',
    );
  }

  Future<void> addOrUpdateBirthday(Birthday birthday) async {
    final existingIndex = _birthdays.indexWhere((b) => b.id == birthday.id);

    if (existingIndex != -1) {
      final existing = _birthdays[existingIndex];
      if (existing != birthday) {
        await updateBirthday(birthday);
      }
    } else {
      await addBirthday(birthday);
    }
  }

  /// Manually trigger a background sync. Used after Google sign-in so
  /// the user doesn't wait for the next auth stream emission.
  Future<void> triggerSync() async {
    if (!_isAuthenticated) return;
    await _syncManager?.syncAll();
    _birthdays = await _repository.getBirthdays();
    _safeNotify();
  }

  /// Promote every local-only row to the current Firebase UID and push
  /// them. Returns the count of rows promoted.
  Future<int> migrateLocalDataToCloud() async {
    if (!_isAuthenticated) return 0;
    final uid = _authRepository!.currentUser!.uid;
    final count = await _syncManager?.migrateLocalOnlyTo(uid) ?? 0;
    _birthdays = await _repository.getBirthdays();
    _safeNotify();
    return count;
  }
}
