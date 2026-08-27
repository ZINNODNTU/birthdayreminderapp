import '../../../models/birthday.dart';
import 'birthday_engine.dart';
import 'birthday_occurrence.dart';
import 'lunar_calendar_service.dart';

/// Default [BirthdayEngine] backed by the [LunarCalendarService].
///
/// Policies (Phase 3):
/// * **Solar recurrence**: same month/day, target year.
/// * **Lunar recurrence**: lunar(day, month, targetYear) → solar(targetYear).
///   The stored `lunarBirthday.year` is intentionally ignored.
/// * **February 29**: in non-leap years the birthday is observed on
///   February 28. Callers wanting March 1 should post-process.
/// * **Today is the day**: `daysUntil = 0` and `nextOccurrence = today`.
/// * **Lunar leap months**: not currently modelled (no `isLunarLeapMonth`
///   column on disk). Existing records therefore ignore leap-month
///   semantics and may land on the regular month in the target year.
class DefaultBirthdayEngine implements BirthdayEngine {
  const DefaultBirthdayEngine(this._calendar);

  final LunarCalendarService _calendar;

  static const int febNonLeapDay = 28;

  /// Strip the time-of-day so we compare day-by-day.
  static DateTime _truncate(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  DateTime occurrenceInYear(Birthday birthday, int year) {
    switch (birthday.calendarType) {
      case CalendarType.solar:
        return _safeSolar(
          year,
          birthday.solarBirthday.month,
          birthday.solarBirthday.day,
        );
      case CalendarType.lunar:
        return _calendar.toSolarForYear(birthday.lunarBirthday, year);
    }
  }

  /// Build a solar DateTime, falling back to Feb 28 when Feb 29 would
  /// be invalid in the target year.
  DateTime _safeSolar(int year, int month, int day) {
    if (month == 2 && day == 29 && !_isLeapYear(year)) {
      return DateTime(year, 2, febNonLeapDay);
    }
    return DateTime(year, month, day);
  }

  bool _isLeapYear(int year) =>
      (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

  @override
  DateTime nextOccurrence(Birthday birthday, {DateTime? from}) {
    final today = _truncate(from ?? DateTime.now());
    final candidateThisYear = occurrenceInYear(birthday, today.year);
    if (!_truncate(candidateThisYear).isBefore(today)) {
      return candidateThisYear;
    }
    return occurrenceInYear(birthday, today.year + 1);
  }

  @override
  int daysUntilNextBirthday(Birthday birthday, {DateTime? from}) {
    final today = _truncate(from ?? DateTime.now());
    final next = _truncate(nextOccurrence(birthday, from: today));
    // (next - today) computed from local-day midnight to avoid DST drift.
    return next.difference(today).inDays;
  }

  @override
  int ageAtOccurrence(Birthday birthday, {DateTime? occurrence}) {
    final occ = _truncate(occurrence ?? nextOccurrence(birthday));
    switch (birthday.calendarType) {
      case CalendarType.solar:
        // True age: subtract a year if the occurrence has not yet
        // reached the birthday's month/day.
        var age = occ.year - birthday.solarBirthday.year;
        final beforeBirthday = occ.month < birthday.solarBirthday.month ||
            (occ.month == birthday.solarBirthday.month &&
                occ.day < birthday.solarBirthday.day);
        if (beforeBirthday) age--;
        return age;
      case CalendarType.lunar:
        // For lunar birthdays we anchor "birth year" to the stored
        // lunar year. This matches the user's mental model — "you were
        // born in the lunar year of the tiger" — and stays consistent
        // regardless of how the calendar shifts.
        return occ.year - birthday.lunarBirthday.year;
    }
  }

  @override
  BirthdayOccurrence snapshot(Birthday birthday, {DateTime? from}) {
    final today = _truncate(from ?? DateTime.now());
    final next = _truncate(nextOccurrence(birthday, from: today));
    return BirthdayOccurrence(
      date: next,
      age: ageAtOccurrence(birthday, occurrence: next),
      daysUntil: next.difference(today).inDays,
    );
  }
}
