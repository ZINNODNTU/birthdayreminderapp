/// Status of the OS notification capabilities we need.
enum NotificationCapability {
  /// POST_NOTIFICATIONS granted; SCHEDULE_EXACT_ALARM granted too.
  fullAccess,

  /// POST_NOTIFICATIONS granted but exact alarms not available.
  /// We fall back to inexact scheduling.
  inexactOnly,

  /// User denied POST_NOTIFICATIONS. Birthday storage still works
  /// but no reminders will fire.
  denied,

  /// Initialisation or capability query failed. Treat as denied but
  /// surface the failure to logs.
  error,
}

class NotificationCapabilities {
  const NotificationCapabilities({
    required this.postNotifications,
    required this.exactAlarms,
  });

  final bool postNotifications;
  final bool exactAlarms;

  NotificationCapability get status {
    if (!postNotifications) return NotificationCapability.denied;
    if (!exactAlarms) return NotificationCapability.inexactOnly;
    return NotificationCapability.fullAccess;
  }
}
