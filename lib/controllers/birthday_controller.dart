import 'package:flutter/foundation.dart';

import '../features/birthdays/data/birthday_repository.dart';
import '../features/birthdays/domain/birthday_engine.dart';
import '../services/notification_service.dart';
import '../features/reminders/services/reminder_scheduler.dart';
import '../models/birthday.dart';

/// Owns the in-memory list of birthdays and forwards mutations to the
/// repository and the reminder scheduler.
class BirthdayController with ChangeNotifier {
  BirthdayController({
    required BirthdayRepository repository,
    required ReminderScheduler reminderScheduler,
    required NotificationService notificationService,
    required BirthdayEngine engine,
  }) : _repository = repository,
       _scheduler = reminderScheduler,
       _notificationService = notificationService,
       _engine = engine {
    loadBirthdays();
  }

  final BirthdayRepository _repository;
  final ReminderScheduler _scheduler;
  final NotificationService _notificationService;
  final BirthdayEngine _engine;

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
    await _scheduler.scheduleNext(birthday);
  }

  Future<void> updateBirthday(Birthday birthday) async {
    await _repository.updateBirthday(birthday);
    final index = _birthdays.indexWhere((b) => b.id == birthday.id);
    if (index != -1) {
      _birthdays[index] = birthday;
      _safeNotify();
    }
    await _scheduler.scheduleNext(birthday);
  }

  Future<void> deleteBirthday(String id) async {
    await _scheduler.cancelAllFor(id);
    await _repository.deleteBirthday(id);
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
        await _repository.updateBirthday(birthday);
        _birthdays[existingIndex] = birthday;
        _safeNotify();
        await _scheduler.scheduleNext(birthday);
      }
    } else {
      await _repository.createBirthday(birthday);
      _birthdays = await _repository.getBirthdays();
      _safeNotify();
      await _scheduler.scheduleNext(birthday);
    }
  }
}
