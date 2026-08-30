import '../../../models/birthday.dart';
import '../../birthdays/domain/birthday_engine.dart';

/// Structured, testable notification payload shared by the scheduled
/// reminder and the manual "thông báo thử" path. Using one builder
/// keeps the test notification bit-for-bit faithful to what the user
/// will see on the actual reminder.
class BirthdayNotificationContent {
  const BirthdayNotificationContent({
    required this.title,
    required this.body,
    required this.occurrenceDate,
    required this.occurrenceYear,
  });

  final String title;
  final String body;
  final DateTime occurrenceDate;
  final int occurrenceYear;

  bool containsName(String name) => title.contains(name) || body.contains(name);
}

/// Build the reminder/test notification payload from a [Birthday].
///
/// [occurrence] should be the solar occurrence of this birthday in the
/// year the notification represents (today's year for the day-of, or
/// the next year for a "soon" preview). Tests can pass an arbitrary
/// occurrence to cover edge cases without touching the clock.
class BirthdayNotificationFormatter {
  const BirthdayNotificationFormatter();

  static const String testChannelId = 'birthday_test_v2';
  static const String testChannelName = 'Thông báo thử';

  static const int testNotificationId = 0x6E5F00D;

  /// True when [birthday] is set to fire on [occurrence] (same
  /// month/day, with the calendar type resolved via [engine]).
  bool isOccurrenceToday(
    Birthday birthday,
    DateTime occurrence,
    BirthdayEngine engine,
  ) {
    final today = DateTime.now();
    if (occurrence.year != today.year) return false;
    return engine.occurrenceInYear(birthday, today.year) ==
        DateTime(today.year, occurrence.month, occurrence.day);
  }

  /// Compute the notification age from the occurrence year. Lunar and
  /// solar both funnel through the same arithmetic so callers never
  /// have to special-case `birthday.solarBirthday.year`.
  int ageForOccurrence(Birthday birthday, DateTime occurrence) {
    final birth = birthday.solarBirthday;
    var age = occurrence.year - birth.year;
    if (occurrence.month < birth.month ||
        (occurrence.month == birth.month && occurrence.day < birth.day)) {
      age--;
    }
    return age;
  }

  BirthdayNotificationContent buildForOccurrence({
    required Birthday birthday,
    required DateTime occurrence,
    BirthdayEngine? engine,
  }) {
    final occDay = DateTime(occurrence.year, occurrence.month, occurrence.day);
    final age = ageForOccurrence(birthday, occDay);
    final display =
        birthday.nickname?.isNotEmpty == true
            ? '${birthday.name} (${birthday.nickname})'
            : birthday.name;
    final now = DateTime.now();
    final isToday =
        now.year == occDay.year &&
        now.month == occDay.month &&
        now.day == occDay.day;
    final title =
        isToday ? '🎂 Sinh nhật của $display' : '🎂 Sắp đến sinh nhật $display';
    final relation =
        birthday.relationship?.trim().isNotEmpty == true
            ? ' (${birthday.relationship})'
            : '';
    final body =
        isToday
            ? 'Hôm nay là sinh nhật$relation của $display'
                '${age >= 0 ? ' ($age tuổi)' : ''}. '
                'Đừng quên gửi lời chúc!'
            : '$display sẽ có sinh nhật vào ngày '
                '${occDay.day.toString().padLeft(2, '0')}/'
                '${occDay.month.toString().padLeft(2, '0')}';
    return BirthdayNotificationContent(
      title: title,
      body: body,
      occurrenceDate: occDay,
      occurrenceYear: occDay.year,
    );
  }
}

/// Convenience provider lookup for the formatter used by controllers.
BirthdayNotificationFormatter buildNotificationFormatter() =>
    const BirthdayNotificationFormatter();
