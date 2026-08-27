/// Result of a scheduler call. Never throws for permission / exact
/// alarm issues — those become [NotificationFailureKind].
enum NotificationFailureKind {
  none,
  permissionDenied,
  exactAlarmDenied,
  scheduleFailed,
  cancelFailed,
  timezoneFailed,
  initializationFailed,
}

class ReminderScheduleResult {
  const ReminderScheduleResult({
    required this.kind,
    required this.scheduledCount,
    this.message,
  });

  factory ReminderScheduleResult.ok({int scheduledCount = 1}) =>
      ReminderScheduleResult(
        kind: NotificationFailureKind.none,
        scheduledCount: scheduledCount,
      );

  factory ReminderScheduleResult.failure({
    required NotificationFailureKind kind,
    String? message,
  }) => ReminderScheduleResult(kind: kind, scheduledCount: 0, message: message);

  final NotificationFailureKind kind;
  final int scheduledCount;
  final String? message;

  bool get isOk => kind == NotificationFailureKind.none;
}

class ReminderReconcileResult {
  const ReminderReconcileResult({
    required this.kind,
    required this.cancelled,
    required this.scheduled,
    this.message,
  });

  factory ReminderReconcileResult.ok({int cancelled = 0, int scheduled = 0}) =>
      ReminderReconcileResult(
        kind: NotificationFailureKind.none,
        cancelled: cancelled,
        scheduled: scheduled,
      );

  final NotificationFailureKind kind;
  final int cancelled;
  final int scheduled;
  final String? message;

  bool get isOk => kind == NotificationFailureKind.none;
}
