/// Concrete, scheduled reminder that the OS will fire.
///
/// [scheduleKey] is the *only* input that determines the
/// [notificationId]. The id factory hashes the key deterministically
/// so that reschedules / restarts / app updates always pick the same
/// integer.
///
/// Key format (rolling horizon):
///   `birthday:<id>:year:<YYYY>:primary`
///
/// That format guarantees every (birthday, year) pair gets its own
/// pending alarm — both on Android and in the
/// [ReminderScheduleStore]. Editing a birthday invalidates every key
/// for it, so the old ids become orphan and are dropped by the
/// reconciler.
class ReminderSchedule {
  const ReminderSchedule({
    required this.scheduleKey,
    required this.notificationId,
    required this.birthdayId,
    required this.occurrenceDate,
    required this.occurrenceYear,
    required this.scheduledAt,
    required this.title,
    required this.body,
    required this.payload,
  });

  /// Deterministic key: `birthday:<id>:year:<YYYY>:primary`.
  final String scheduleKey;

  /// Integer id used by `flutter_local_notifications`.
  final int notificationId;

  /// Birthday this reminder belongs to.
  final String birthdayId;

  /// The actual solar birthday occurrence this reminder points at
  /// (date only — no time).
  final DateTime occurrenceDate;

  /// Target year used by the engine to compute [occurrenceDate].
  /// Stored alongside the date so the reconciler can decide whether a
  /// past year entry should be removed.
  final int occurrenceYear;

  /// The instant the OS should fire the notification.
  final DateTime scheduledAt;

  final String title;
  final String body;
  final String payload;
}
