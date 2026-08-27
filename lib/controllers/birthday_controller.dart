import 'package:flutter/material.dart';
import '../models/birthday.dart';
import '../services/local_db_service.dart';
import '../services/notification_service.dart';

class BirthdayController with ChangeNotifier {
  final LocalDBService _localDbService = LocalDBService();
  final NotificationService _notificationService = NotificationService();

  List<Birthday> _birthdays = [];

  List<Birthday> get birthdays => _birthdays;

  BirthdayController({bool skipInit = false}) {
    if (!skipInit) _init();
  }

  Future<void> _init() async {
    await _notificationService.initialize(); // Đảm bảo thông báo được khởi tạo
    await loadBirthdays();
  }

  Future<void> loadBirthdays() async {
    _birthdays = await _localDbService.getBirthdays();
    notifyListeners();
  }

  Future<void> addBirthday(Birthday birthday) async {
    await _localDbService.insertBirthday(birthday);
    _birthdays.add(birthday);
    notifyListeners();

    if (birthday.isRecurringNotificationEnabled) {
      await _notificationService.scheduleBirthdayNotification(birthday);
    }
  }

  Future<void> updateBirthday(Birthday birthday) async {
    await _localDbService.updateBirthday(birthday);
    final index = _birthdays.indexWhere((b) => b.id == birthday.id);
    if (index != -1) {
      _birthdays[index] = birthday;
      notifyListeners();
    }

    // Hủy thông báo cũ trước khi lập lại (dù người dùng có thay đổi thời gian hay không)
    await _notificationService.cancelNotification(birthday.id);

    if (birthday.isRecurringNotificationEnabled) {
      await _notificationService.scheduleBirthdayNotification(birthday);
    }
  }

  Future<void> deleteBirthday(String id) async {
    await _localDbService.deleteBirthday(id);
    _birthdays.removeWhere((b) => b.id == id);
    notifyListeners();

    await _notificationService.cancelNotification(id);
  }

  Future<void> testNotification(Birthday birthday) async {
    await _notificationService.testNotification(birthday);
  }

  /// Dùng trong trường hợp thêm từ danh bạ hoặc import, tránh trùng lặp
  Future<void> addOrUpdateBirthday(Birthday birthday) async {
    final existingIndex = _birthdays.indexWhere((b) => b.id == birthday.id);

    if (existingIndex != -1) {
      final existing = _birthdays[existingIndex];

      if (existing != birthday) {
        _birthdays[existingIndex] = birthday;
        await _localDbService.updateBirthday(birthday);
        notifyListeners();

        await _notificationService.cancelNotification(birthday.id);
        if (birthday.isRecurringNotificationEnabled) {
          await _notificationService.scheduleBirthdayNotification(birthday);
        }
      }
    } else {
      _birthdays.add(birthday);
      await _localDbService.insertBirthday(birthday);
      notifyListeners();

      if (birthday.isRecurringNotificationEnabled) {
        await _notificationService.scheduleBirthdayNotification(birthday);
      }
    }
  }
}
