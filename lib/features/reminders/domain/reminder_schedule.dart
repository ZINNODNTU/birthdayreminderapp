/// Concrete, scheduled reminder that the OS will fire.
///
/// [scheduleKey] is the *only* input that determines the
/// [notificationId]. The id factory hashes the key deterministically
/// so that reschedules / restarts / app updates always pick the same
/// integer.
class ReminderSchedule {
  const ReminderSchedule({
    required this.scheduleKey,
    required this.notificationId,
    required this.birthdayId,
    required this.occurrenceDate,
    required this.scheduledAt,
    required this.title,
    required this.body,
    required this.payload,
  });

  /// Human-readable, deterministic key:
  /// `birthday:<id>:daysBefore:<N>:h:<HH>:m:<MM>`
  final String scheduleKey;

  /// Integer id used by `flutter_local_notifications`.
  final int notificationId;

  /// Birthday this reminder belongs to.
  final String birthdayId;

  /// The actual solar birthday occurrence this reminder points at
  /// (date only — no time).
  final DateTime occurrenceDate;

  /// The instant the OS should fire the notification.
  final DateTime scheduledAt;

  final String title;
  final String body;
  final String payload;
}
