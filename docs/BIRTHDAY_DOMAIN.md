# Birthday Domain

## Scope
The birthday domain owns recurrence, age and "days until" calculations.
Everything that asks "when is the next birthday?" goes through
`BirthdayEngine`. Views and services do not compute dates locally.

## Files

- `lib/features/birthdays/domain/lunar_calendar_service.dart` —
  pure Solar ↔ Lunar conversion. No business logic.
- `lib/features/birthdays/domain/birthday_engine.dart` — abstract
  interface.
- `lib/features/birthdays/domain/default_birthday_engine.dart` —
  the only production implementation.
- `lib/features/birthdays/domain/birthday_occurrence.dart` —
  `(date, age, daysUntil)` value object returned by
  `BirthdayEngine.snapshot()`.

## Policies (Phase 3)

### Solar recurrence
A solar birthday `(m, d, y_birth)` occurs on `(y, m, d)` for any
target year `y`. Always rebuilt from the stored month/day; the stored
year is never reused.

### Lunar recurrence (the fix)
A lunar birthday `(d, m, y_lunar)` occurs on
`Lunar.fromYmd(y, m, d).getSolar()` for any target year `y`. The stored
`y_lunar` is **deliberately ignored**: lunar→solar alignment drifts
each year, so a recurring lunar birthday must be re-converted every
year.

The previous bug used the stored `y_lunar` instead of the target year,
which produced the same solar date every year.

### February 29
In a non-leap year, a Feb 29 birthday is observed on **Feb 28**. We do
not roll forward to March 1 — that would surprise users with a
"phantom" birthday.

### Age
- **Solar**: `occ.year − birth.year`, then `−1` if the occurrence has
  not yet reached the birthday's month/day in the target year. This
  matches the standard calendar-age definition.
- **Lunar**: `occ.year − lunarBirthday.year`. The user's mental model
  is anchored to the lunar year of birth, not the day-of-lunar-month.

### `nextOccurrence`
`candidate = occurrenceInYear(currentYear)`. If `candidate` is on or
after today, return it; otherwise return
`occurrenceInYear(currentYear + 1)`.

Time of day is ignored for the comparison — dates are normalised to
local midnight.

### `daysUntilNextBirthday`
0 when today is the day; whole days otherwise. DST-safe because we
subtract `DateTime(y, m, day)` values, not `Duration`s.

## Lunar leap months

**Status: NOT PERSISTED.** The on-disk `Birthday` model has no
`isLunarLeapMonth` column. The `LunarCalendarService` exposes
`isLeapLunarMonth(year, month)` so a higher layer could read the flag
when we eventually add the column (DB v3). Existing records that
happen to be leap-month birthdays will be resolved as the regular
month in the target year — this is documented as a known limitation.

## CalendarView refactor

CalendarView now reads `BirthdayEngine` via Provider and resolves
each birthday through `engine.occurrenceInYear(b, focusedYear)`.
`lunarBirthday.toSolarDateTime()` is no longer called from view code.

## NotificationService refactor

`scheduleBirthdayNotification(birthday, engine)` and
`testNotification(birthday, engine)` accept an engine. The scheduled
time is still the local-midnight + `remindTime` pair from the
birthday record. **Phase 4** will tackle notification IDs.

## Timezone

All comparisons happen on local-day-midnight DateTimes. The
notification service converts to `tz.TZDateTime.local` for
`zonedSchedule`. UTC offsets are not part of the domain.
