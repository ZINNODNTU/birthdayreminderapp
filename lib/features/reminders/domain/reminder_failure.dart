/// Result of a scheduler call. Never throws for permission / exact
/// alarm issues — those become [NotificationFailureKind].
enum NotificationFailureKind {
  none,
  permissionDenied,
  notificationsDisabled,
  exactAlarmDenied,
  exactUnavailableUsingFallback,
  invalidScheduleTime,
  timezoneFailure,
  initializationFailed,
  scheduleFailed,
  pendingVerificationFailed,
  cancelFailed,
}

class ReminderScheduleResult {
  const ReminderScheduleResult({
    required this.kind,
    required this.scheduledCount,
    this.message,
    this.scheduledAt,
    this.notificationId,
    this.exact = false,
  });

  factory ReminderScheduleResult.ok({
    int scheduledCount = 1,
    DateTime? scheduledAt,
    int? notificationId,
    bool exact = false,
  }) => ReminderScheduleResult(
    kind: NotificationFailureKind.none,
    scheduledCount: scheduledCount,
    scheduledAt: scheduledAt,
    notificationId: notificationId,
    exact: exact,
  );

  factory ReminderScheduleResult.failure({
    required NotificationFailureKind kind,
    String? message,
  }) => ReminderScheduleResult(kind: kind, scheduledCount: 0, message: message);

  final NotificationFailureKind kind;
  final int scheduledCount;
  final String? message;
  final DateTime? scheduledAt;
  final int? notificationId;
  final bool exact;

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

/// Friendly Vietnamese explanations for each [NotificationFailureKind].
/// Used by the detail screen and Settings page.
String describeNotificationFailure(NotificationFailureKind k) {
  switch (k) {
    case NotificationFailureKind.none:
      return 'Đã lên lịch nhắc nhở.';
    case NotificationFailureKind.permissionDenied:
      return 'Chưa cấp quyền thông báo — không thể đặt lịch.';
    case NotificationFailureKind.notificationsDisabled:
      return 'Thông báo đang bị tắt ở cài đặt thiết bị.';
    case NotificationFailureKind.exactAlarmDenied:
      return 'Đã đặt nhắc nhưng thiết bị có thể gửi trễ '
          '(chưa cấp báo thức chính xác).';
    case NotificationFailureKind.exactUnavailableUsingFallback:
      return 'Thiết bị không hỗ trợ báo thức chính xác — đã đặt lịch ở chế độ '
          'không chính xác, có thể gửi trễ vài phút.';
    case NotificationFailureKind.invalidScheduleTime:
      return 'Thời điểm nhắc đã qua — bỏ qua lần nhắc này.';
    case NotificationFailureKind.timezoneFailure:
      return 'Không khởi tạo được múi giờ thiết bị.';
    case NotificationFailureKind.initializationFailed:
      return 'Khởi tạo thông báo thất bại.';
    case NotificationFailureKind.pendingVerificationFailed:
      return 'Đã lên lịch nhưng không xác nhận được với hệ thống — sẽ thử lại.';
    case NotificationFailureKind.scheduleFailed:
      return 'Không thể đặt lịch — kiểm tra lại cấu hình.';
    case NotificationFailureKind.cancelFailed:
      return 'Không thể hủy lịch cũ.';
  }
}
