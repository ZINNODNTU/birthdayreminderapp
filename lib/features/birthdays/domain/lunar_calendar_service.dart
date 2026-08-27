import 'package:lunar/lunar.dart';

import '../../../models/birthday.dart';

/// Pure conversion utilities between Solar and Lunar dates.
///
/// This class has no business logic for "next birthday" / "age" / etc. —
/// those live in [BirthdayEngine]. It only knows how to convert.
class LunarCalendarService {
  const LunarCalendarService();

  /// Convert a solar [DateTime] to its lunar representation. The time
  /// component is discarded — only year/month/day are used.
  LunarDateTime toLunar(DateTime solarDate) {
    final lunar = Lunar.fromDate(solarDate);
    return LunarDateTime(
      day: lunar.getDay(),
      month: lunar.getMonth(),
      year: lunar.getYear(),
    );
  }

  /// Convert a stored lunar date to a solar [DateTime]. The source's
  /// stored `year` is honored. Use [toSolarForYear] when you need the
  /// *target*-year mapping (e.g. recurring birthday).
  DateTime toSolar(LunarDateTime lunarDate) {
    final lunar = Lunar.fromYmd(lunarDate.year, lunarDate.month, lunarDate.day);
    final solar = lunar.getSolar();
    return DateTime(solar.getYear(), solar.getMonth(), solar.getDay());
  }

  /// Convert a stored lunar (day, month) into the solar date that
  /// represents the same lunar day/month in the requested [targetYear].
  ///
  /// This is the correct call for *recurring* lunar birthdays: the
  /// stored `year` is intentionally ignored because lunar→solar shifts
  /// each year.
  DateTime toSolarForYear(LunarDateTime lunarDate, int targetYear) {
    final lunar = Lunar.fromYmd(targetYear, lunarDate.month, lunarDate.day);
    final solar = lunar.getSolar();
    return DateTime(solar.getYear(), solar.getMonth(), solar.getDay());
  }

  /// Whether the given lunar (year, month) is a leap lunar month.
  /// The current `Birthday` model does NOT persist this flag, so the
  /// `DefaultBirthdayEngine` ignores it. A future schema bump can
  /// surface this without breaking the converter.
  bool isLeapLunarMonth(int year, int month) {
    return LunarYear.fromYear(year).getLeapMonth() == month;
  }
}
