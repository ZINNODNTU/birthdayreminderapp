import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/auth/auth_repository.dart';
import '../features/birthdays/data/birthday_repository.dart';
import '../core/db/sync_status.dart';
import '../features/birthdays/domain/birthday_sync_copy.dart';
import '../features/birthdays/domain/birthday_engine.dart';
import '../features/birthdays/data/local_birthday_repository.dart';
import '../features/birthdays/services/birthday_photo_service.dart';
import '../features/sync/sync_manager.dart';
import '../services/notification_service.dart';
import '../features/reminders/services/reminder_scheduler.dart';
import '../core/logging/app_logger.dart';
import '../features/reminders/domain/birthday_notification_formatter.dart';
import '../features/reminders/domain/reminder_failure.dart';
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
    BirthdayPhotoService? photoService,
  }) : _repository = repository,
       _scheduler = reminderScheduler,
       _notificationService = notificationService,
       _engine = engine,
       _authRepository = authRepository,
       _syncManager = syncManager,
       _photoService = photoService ?? const BirthdayPhotoService() {
    // Fire-and-forget but guarded: a sync throw during repository
    // initialisation (e.g. SQLite unavailable right after Google
    // sign-in) must NEVER leave the controller in a half-initialised
    // state — the widget tree would otherwise render an empty body.
    _bootstrap();
  }

  final BirthdayRepository _repository;
  final ReminderScheduler _scheduler;
  final NotificationService _notificationService;
  final BirthdayEngine _engine;
  final AuthRepository? _authRepository;
  final SyncManager? _syncManager;
  final BirthdayPhotoService _photoService;

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

  bool get isAuthenticated =>
      _authRepository?.currentUser != null &&
      _authRepository!.currentUser!.uid.isNotEmpty;

  /// Wrap a row with the correct sync metadata given the current
  /// authentication state. Local-only rows keep
  /// `syncStatus: localOnly`; authenticated rows become
  /// `pendingUpload`.
  Birthday _stampForSync(Birthday b) {
    final now = DateTime.now();
    if (!isAuthenticated) {
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

  Future<void> _bootstrap() async {
    try {
      await loadBirthdays();
    } catch (e, st) {
      AppLogger.warn(
        'BirthdayController',
        'initial loadBirthdays failed: $e\n$st',
      );
      // Surface empty state so the UI keeps rendering the calendar
      // shell instead of a blank body.
      _birthdays = const [];
      _safeNotify();
    }
  }

  Future<void> loadBirthdays() async {
    _birthdays = await _repository.getBirthdays();
    _safeNotify();
    // Fire-and-forget background reconciliation after every load.
    if (isAuthenticated) {
      unawaited(_syncManager?.syncAll());
    }
  }

  void Function(ReminderScheduleResult)? onReminderScheduled;
  void Function(NotificationFailureKind)? onReminderFailed;

  Future<void> addBirthday(Birthday birthday) async {
    final compressed = await _maybeCompressPhoto(birthday);
    final stamped = _stampForSync(compressed);
    await _repository.createBirthday(stamped);
    _birthdays = await _repository.getBirthdays();
    _safeNotify();
    final result = await _scheduler.scheduleNextAnnualReminder(stamped);
    _emitScheduleResult(result);
    if (isAuthenticated) {
      unawaited(_syncManager?.syncAll());
    }
  }

  Future<void> updateBirthday(Birthday birthday) async {
    final compressed = await _maybeCompressPhoto(birthday);
    final stamped = _stampForSync(compressed);
    await _repository.updateBirthday(stamped);
    final index = _birthdays.indexWhere((b) => b.id == stamped.id);
    if (index != -1) {
      _birthdays[index] = stamped;
      _safeNotify();
    }
    final result = await _scheduler.scheduleNextAnnualReminder(stamped);
    _emitScheduleResult(result);
    if (isAuthenticated) {
      unawaited(_syncManager?.syncAll());
    }
  }

  void _emitScheduleResult(ReminderScheduleResult result) {
    if (result.isOk) {
      onReminderScheduled?.call(result);
    } else {
      onReminderFailed?.call(result.kind);
    }
  }

  /// Re-encode the attached avatar so it satisfies the cloud size
  /// budget. Silently falls back to the original bytes when the
  /// input is already valid (idempotent). Returns the original
  /// birthday untouched when there is no avatar at all.
  Future<Birthday> _maybeCompressPhoto(Birthday b) async {
    if (b.avatarBase64 == null || b.avatarBase64!.isEmpty) return b;
    final encoded = await _photoService.encodeForCloud(
      base64Input: b.avatarBase64!,
    );
    if (!encoded.ok) {
      AppLogger.warn(
        'BirthdayController',
        'photo compression failed for ${b.id}: ${encoded.failure} '
            '— keeping original',
      );
      return b;
    }
    return b.copyWith(avatarBase64: encoded.photo!.base64);
  }

  /// Result of a delete attempt. Returned to callers so the UI can
  /// surface a SnackBar without catching exceptions.
  ///
  /// Behaviour:
  ///   * Authenticated: write a local tombstone row (deletedAt set,
  ///     syncStatus=pendingDelete). Cloud is NEVER touched here.
  ///   * Local mode: write a local tombstone row (deletedAt set,
  ///     syncStatus=localOnly).
  ///   * In either mode the in-memory visible list drops the row.
  ///   * The caller must not assume a cloud write happened — the
  ///     sync engine will push the tombstone later, preserving every
  ///     original field via Firestore soft-delete.
  Future<bool> deleteBirthday(String id) async {
    AppLogger.debug(
      'BirthdayDelete',
      'requested id=$id mode=${isAuthenticated ? 'authenticated' : 'local'}',
    );
    final existing = await _repository.getBirthday(id);
    if (existing == null) {
      AppLogger.warn('BirthdayDelete', 'id=$id not found');
      return false;
    }
    try {
      await _scheduler.cancelAllFor(id);
      AppLogger.debug('BirthdayDelete', 'reminder cancelled id=$id');
    } catch (e, st) {
      AppLogger.warn('BirthdayDelete', 'cancel reminder failed: $e\n$st');
    }
    final now = DateTime.now();
    final stamped = existing.copyWith(
      deletedAt: now,
      updatedAt: now,
      syncStatus: isAuthenticated
          ? SyncStatus.pendingDelete
          : SyncStatus.localOnly,
      ownerUid: isAuthenticated ? _authRepository!.currentUser!.uid : null,
    );
    await _repository.upsertBirthday(stamped);
    AppLogger.debug(
      'BirthdayDelete',
      'local tombstone saved id=$id '
          'status=${stamped.syncStatus.name}',
    );
    // Hide from UI immediately.
    _birthdays = _birthdays.where((b) => b.id != id).toList();
    _safeNotify();
    // CRITICAL: never call syncManager.syncAll() here. Cloud must
    // remain untouched until the user (or the next normal sync cycle)
    // pushes the tombstone through pushPending().
    return true;
  }

  Future<NotificationTestResult> testNotification(Birthday birthday) async {
    final now = DateTime.now();
    final thisYearOccur = _engine.occurrenceInYear(birthday, now.year);
    final DateTime occurrence;
    if (thisYearOccur.isAfter(now)) {
      occurrence = thisYearOccur;
    } else {
      occurrence = _engine.occurrenceInYear(birthday, now.year + 1);
    }
    final payload = const BirthdayNotificationFormatter().buildForOccurrence(
      birthday: birthday,
      occurrence: occurrence,
    );
    return _notificationService.showTestNotification(
      title: payload.title,
      body: payload.body,
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
  Future<void> triggerSync({
    void Function(int current, int total)? onProgress,
  }) async {
    if (!isAuthenticated) return;
    await _syncManager?.syncAll(onProgress: onProgress);
    _birthdays = await _repository.getBirthdays();
    _safeNotify();
  }

  /// Promote every local-only row to the current Firebase UID and push
  /// them. Returns the count of rows promoted.
  Future<int> migrateLocalDataToCloud() async {
    if (!isAuthenticated) return 0;
    final uid = _authRepository!.currentUser!.uid;
    final count = await _syncManager?.migrateLocalOnlyTo(uid) ?? 0;
    _birthdays = await _repository.getBirthdays();
    _safeNotify();
    return count;
  }
}
