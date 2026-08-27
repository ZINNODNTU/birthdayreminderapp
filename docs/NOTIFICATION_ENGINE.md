# Notification Engine

## Scope
Production-grade scheduling for birthday reminders. The engine
covers deterministic ids, exact/inexact alarms, timezone, Android 13
permission flow, Android 12+ exact-alarm capability, boot/package
replacement reconciliation and graceful denial fallbacks.

## Files

- `lib/features/reminders/domain/` — pure value objects:
  `ReminderRule`, `ReminderSchedule`, `NotificationCapability`,
  `NotificationFailureKind` + result types.
- `lib/features/reminders/data/reminder_schedule_store.dart` —
  lightweight SharedPreferences registry of managed ids.
- `lib/features/reminders/services/notification_id_factory.dart`
  — deterministic FNV-1a 31-bit id factory.
- `lib/features/reminders/services/notification_timezone_bootstrap.dart`
  — initialises `tz.local` from the device's reported timezone,
    falls back to UTC.
- `lib/features/reminders/services/notification_permission_service.dart`
  — queries / requests POST_NOTIFICATIONS and SCHEDULE_EXACT_ALARM.
- `lib/features/reminders/services/reminder_scheduler.dart` —
  single entry-point for "schedule the next reminder for this
  birthday". Pure `ReminderScheduleBuilder` + the orchestrating
  `ReminderScheduler`.
- `lib/features/reminders/services/notification_reconciler.dart` —
  compares desired reminders with the OS-managed set, cancels
  stale ones, schedules missing ones.
- `lib/services/notification_service.dart` — thin adapter around
  `flutter_local_notifications`. No ID logic, no engine.

## ID strategy
- The id of every scheduled reminder is derived solely from the
  *schedule key*:
  `birthday:<id>:daysBefore:<N>:h:<HH>:m:<MM>`
- The factory hashes the key with FNV-1a 32-bit, masks off the
  sign bit, and returns a positive 31-bit integer.
- `String.hashCode` is intentionally NOT used because Dart does
  not guarantee hash stability across runtimes.
- A test-only notification id (`0x6E5F00D`) lives outside the
  schedule-key namespace so the "test notification" button cannot
  collide with real reminders.

## Schedule key
`birthday:<id>:daysBefore:<N>:h:<HH>:m:<MM>`

If the user changes `daysBefore`, `hour` or `minute`, the key
changes and the scheduler can cancel the previous id and schedule
a new one with a different deterministic id.

## Reminder math
- `nextOccurrence(birthday, from)` → via `BirthdayEngine`.
- `scheduledAt = occurrenceDate @ remindTime − daysBefore`.
- If `scheduledAt <= now`, roll forward to the next occurrence.
- One scheduled alarm per birthday — multi-rule is future work.

## Lunar annual recurrence
Lunar birthdays re-convert per target year, via
`BirthdayEngine.occurrenceInYear(birthday, year)`. The previous
bug (using the stored lunar year) is gone.

## Timezone
- `NotificationTimezoneBootstrap.initialize()` runs once during
  `AppBootstrap.run()`.
- Initialises `timezone/data/latest_all` and sets `tz.local` from
  `flutter_timezone`'s `getLocalTimezone()`.
- On failure it falls back to UTC; logs the error.
- On next app start, the timezone is refreshed and reminders
  are reconciled.

## Exact vs inexact alarms
- `NotificationPermissionService.query()` reads both POST_NOTIFICATIONS
  and `canScheduleExactNotifications()`.
- `fullAccess` → `AndroidScheduleMode.exactAllowWhileIdle`.
- `inexactOnly` → `AndroidScheduleMode.inexactAllowWhileIdle`
  (still fires around the target time, never throws).
- `denied` → scheduler returns `permissionDenied` and the
  `Birthday` is still saved.

## Android 13 notification permission
- Manifest declares `POST_NOTIFICATIONS`.
- The app does NOT request permission on launch.
- It only requests it when the user enables a reminder. This is
  a Phase 4 contract — Phase 6 may add a Settings screen for
  later re-prompts.

## Android 12+ exact alarm
- Manifest keeps `SCHEDULE_EXACT_ALARM` (not `USE_EXACT_ALARM`)
  because the app is a normal calendar/reminder app, not an alarm
  app.
- On Android 14, exact alarms can be revoked at any time.
  `query()` detects this and falls back to inexact.

## Reboot / package replacement
- Manifest declares `RECEIVE_BOOT_COMPLETED` and
  `MY_PACKAGE_REPLACED`, with
  `ScheduledNotificationBootReceiver` from the plugin.
- On next app start, `NotificationReconciler.reconcile()` runs and
  re-syncs every birthday.

## Reconciliation
- Cancels any managed entry whose birthdayId is no longer present.
- Schedules (or re-schedules) every current birthday using
  `ReminderScheduler.scheduleNext`.
- Never calls `cancelAll()` — the app may have non-birthday
  notifications in future.

## Test notification
- The "test notification" button uses
  `NotificationService.testNotificationId` so it cannot overwrite
  a real scheduled alarm.

## Payload
- Payload format: `birthday:<id>`.
- No Birthday object is serialised into the payload.
- No personal notes leak.

## Channel
- Android channel id: `birthday_reminders`.
- Channel name: "Birthday Reminders".
- Importance: `high` (not `max` — no alarm ringtone).

## Local mode
- The reminder scheduler depends only on `BirthdayRepository`
  + `BirthdayEngine`. No Firebase Auth dependency.
- Local-mode birthdays schedule reminders exactly the same way
  as authenticated-mode birthdays.

## iOS
- `DarwinInitializationSettings` requests alert/badge/sound.
- iOS runtime validation requires a Mac and is out of scope for
  this Phase. Static analysis only.

## Known OEM limitations
- Aggressive battery savers on Xiaomi / Oppo / Huawei may kill the
  boot receiver. The reconciler ensures we re-schedule on every
  app start, so the only data lost is the time spent with the app
  in the background.
- These OEM quirks are not in scope for Phase 4 — Phase 7 may
  publish a "keep the app running" guide for affected devices.
