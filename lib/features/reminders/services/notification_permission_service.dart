import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../domain/notification_capability.dart';

/// Adapter over the OS permission APIs. Returns a structured
/// [NotificationCapabilities] rather than booleans so callers can
/// distinguish "POST denied" from "exact alarm denied".
class NotificationPermissionService {
  const NotificationPermissionService();

  Future<NotificationCapabilities> query() async {
    final post = await _queryPost();
    final exact = await _queryExact();
    return NotificationCapabilities(
      postNotifications: post,
      exactAlarms: exact,
    );
  }

  Future<bool> _queryPost() async {
    try {
      final status = await Permission.notification.status;
      if (status.isGranted) return true;
      // On Android < 13 the permission is granted by default and the
      // `status` is `limited/granted` from the platform's perspective.
      if (status.isLimited) return true;
      return false;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _queryExact() async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      final impl =
          plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      if (impl == null) return false;
      final canSchedule = await impl.canScheduleExactNotifications();
      return canSchedule ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Request POST_NOTIFICATIONS. Returns true if granted after the
  /// dialog. Does not auto-relaunch settings on denial.
  Future<bool> requestPostNotifications() async {
    try {
      final status = await Permission.notification.request();
      return status.isGranted || status.isLimited;
    } catch (_) {
      return false;
    }
  }

  /// Open the OS settings page where the user can grant
  /// SCHEDULE_EXACT_ALARM access. No-op when not supported.
  Future<void> requestExactAlarmsAccess() async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      final impl =
          plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      await impl?.requestExactAlarmsPermission();
    } catch (_) {
      // Swallow — caller logs.
    }
  }
}
