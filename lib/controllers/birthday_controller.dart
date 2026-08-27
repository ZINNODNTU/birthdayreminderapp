import 'package:flutter/foundation.dart';

import '../features/birthdays/data/birthday_repository.dart';
import '../models/birthday.dart';
import '../services/notification_service.dart';

/// Owns the in-memory list of birthdays and forwards mutations to the
/// repository and the notification scheduler.
class BirthdayController with ChangeNotifier {
  BirthdayController({
    required BirthdayRepository repository,
    required NotificationService notificationService,
  })  : _repository = repository,
        _notificationService = notificationService {
    loadBirthdays();
  }

  final BirthdayRepository _repository;
  final NotificationService _notificationService;

  List<Birthday> _birthdays = [];
  bool _disposed = false;

  List<Birthday> get birthdays => _birthdays;

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> loadBirthdays() async {
    _birthdays = await _repository.getBirthdays();
    _safeNotify();
  }

  Future<void> addBirthday(Birthday birthday) async {
    await _repository.createBirthday(birthday);
    _birthdays = await _repository.getBirthdays();
    _safeNotify();

    if (birthday.isRecurringNotificationEnabled) {
      await _notificationService.scheduleBirthdayNotification(birthday);
    }
  }

  Future<void> updateBirthday(Birthday birthday) async {
    await _repository.updateBirthday(birthday);
    final index = _birthdays.indexWhere((b) => b.id == birthday.id);
    if (index != -1) {
      _birthdays[index] = birthday;
      _safeNotify();
    }

    await _notificationService.cancelNotification(birthday.id);

    if (birthday.isRecurringNotificationEnabled) {
      await _notificationService.scheduleBirthdayNotification(birthday);
    }
  }

  Future<void> deleteBirthday(String id) async {
    await _repository.deleteBirthday(id);
    _birthdays = await _repository.getBirthdays();
    _safeNotify();

    await _notificationService.cancelNotification(id);
  }

  Future<void> testNotification(Birthday birthday) async {
    await _notificationService.testNotification(birthday);
  }

  /// Used by sync flows (e.g. cloud restore) to add or merge a birthday
  /// without firing notifications.
  Future<void> addOrUpdateBirthday(Birthday birthday) async {
    final existingIndex =
        _birthdays.indexWhere((b) => b.id == birthday.id);

    if (existingIndex != -1) {
      final existing = _birthdays[existingIndex];
      if (existing != birthday) {
        await _repository.updateBirthday(birthday);
        _birthdays[existingIndex] = birthday;
        _safeNotify();

        await _notificationService.cancelNotification(birthday.id);
        if (birthday.isRecurringNotificationEnabled) {
          await _notificationService.scheduleBirthdayNotification(birthday);
        }
      }
    } else {
      await _repository.createBirthday(birthday);
      _birthdays = await _repository.getBirthdays();
      _safeNotify();

      if (birthday.isRecurringNotificationEnabled) {
        await _notificationService.scheduleBirthdayNotification(birthday);
      }
    }
  }
}
