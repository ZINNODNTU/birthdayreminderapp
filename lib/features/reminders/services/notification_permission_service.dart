import '../../../services/notification_service.dart';
import '../domain/notification_capability.dart';

/// Shared permission adapter. All plugin access goes through the initialized
/// [NotificationService] singleton.
class NotificationPermissionService {
  NotificationPermissionService({NotificationService? notificationService})
    : _notificationService = notificationService ?? NotificationService();

  final NotificationService _notificationService;

  Future<NotificationCapabilities> query() async {
    await _notificationService.initialize();
    final post = await _notificationService.areNotificationsEnabled() ?? false;
    final exact =
        await _notificationService.canScheduleExactNotifications() ?? false;
    return NotificationCapabilities(
      postNotifications: post,
      exactAlarms: exact,
    );
  }

  Future<bool> requestPostNotifications() async {
    await _notificationService.initialize();
    return _notificationService.requestNotificationPermission();
  }

  Future<void> requestExactAlarmsAccess() async {
    await _notificationService.initialize();
    await _notificationService.requestExactAlarmsPermission();
  }
}
