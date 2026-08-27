/// A single (date, age, daysUntil) snapshot for a birthday.
class BirthdayOccurrence {
  const BirthdayOccurrence({
    required this.date,
    required this.age,
    required this.daysUntil,
  });

  final DateTime date;

  /// Age the person will be on [date]. For a date in the past this can
  /// be negative (e.g. when computing backwards).
  final int age;

  /// Whole days from "today" (or the caller-supplied reference) until
  /// [date]. 0 means "today", positive means "future", negative means
  /// "past".
  final int daysUntil;
}
