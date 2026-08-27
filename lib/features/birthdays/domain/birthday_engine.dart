import '../../../models/birthday.dart';
import 'birthday_occurrence.dart';

/// All birthday recurrence / age / "days until" calculations go through
/// this engine. Views and services must NOT compute these locally.
abstract interface class BirthdayEngine {
  /// The solar date of this birthday *for the requested [year]*.
  ///
  /// Solar birthdays: same month/day, year replaced.
  /// Lunar birthdays: re-converts lunar(day, month) → solar using
  /// [year], NOT the stored `lunarBirthday.year`. This is the fix for
  /// the long-standing "lunar recurrence" bug.
  DateTime occurrenceInYear(Birthday birthday, int year);

  /// The next future (or today) occurrence of [birthday] relative to
  /// [from]. Defaults to `DateTime.now()` truncated to local day.
  DateTime nextOccurrence(Birthday birthday, {DateTime? from});

  /// Whole days from [from] (default: today) until [nextOccurrence].
  /// Returns 0 when [from] is the same day as the occurrence.
  int daysUntilNextBirthday(Birthday birthday, {DateTime? from});

  /// Age on a given [occurrence] date. Defaults to the next
  /// occurrence.
  int ageAtOccurrence(Birthday birthday, {DateTime? occurrence});

  /// One-shot snapshot — equivalent to calling all of the above.
  BirthdayOccurrence snapshot(Birthday birthday, {DateTime? from});
}
