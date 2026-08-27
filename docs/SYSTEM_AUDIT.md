# Birthday Reminder — System Audit

Baseline: AUTH RECOVERY DONE at commit `d9091e2`. 39 tests pass, analyze clean, APK builds.

## Critical risks

1. Release builds use **debug signing key** (`android/app/build.gradle.kts:42`). Shipping this APK means the next release with a real key cannot be installed as an update (signature mismatch). Users would have to uninstall → reinstall → lose all local data.
2. **Lunar birthday recurrence** computes the date from the *original* lunar year (`LunarDateTime.toSolarDateTime` always uses stored `year`). For every anniversary after the birth year, the lunar date drifts because the lunar→solar mapping shifts each year. Affects `notification_service` scheduling and the calendar/list views.
3. **Notification IDs use `birthday.id.hashCode`** (`notification_service.dart:102, 130`). Multiple birthdays can collide; future edits to `id` (UUID change) silently invalidate existing reminders.

## High risks

1. SQLite `version: 1` with no `onUpgrade` — any future column addition breaks upgrade for existing installs.
2. No schema metadata on `Birthday` (no `ownerUid`, `deletedAt`, `syncStatus`, `schemaVersion`); sync cannot be added without a second migration.
3. No Material 3 / dark mode / settings screen.
4. `BirthdayController` instantiated ad-hoc inside `birthday_detail_view.dart:315` — bypasses Provider and, more importantly, isolates a non-controller state for no reason.
5. No centralised error / failure model; UI surfaces raw exceptions in some flows.

## Technical debt

- `main.dart` mixes bootstrap, DI composition, and theme.
- Views construct `FirestoreService()` and `BirthdayController()` on demand — no composition root.
- `Birthday.toMap()` is reused for SQLite rows AND Firestore writes; the two encodings will diverge as sync grows.
- `gemini_service.dart` is a placeholder that throws `StateError` — callers catch with `catch (_)` and translate to a string. This is fine for now but the contract isn't documented.
- `csv_export_service.dart` requests `MANAGE_EXTERNAL_STORAGE` on Android 13+ — Play would reject it; sideload-only is acceptable for current distribution.

## Recommended migration order

```
Phase 1  Core Architecture          ← THIS BATCH
Phase 2  Local Mode + Data Domain + Migration
Phase 3  Birthday / Lunar Engine
Phase 4  Notification Engine
Phase 5  Cloud Sync
Phase 6  UI/UX + Settings
Phase 7  Self Update / GitHub Releases
Phase 8  AI Backend
Phase 9  Release / CI / Observability
```

## Dependency graph

```
auth (d9091e2)  ── depends on ──► core
                                  ▲
                                  │
                            app (Phase 1)
                                  │
            ┌─────────────────────┼─────────────────────┐
            ▼                     ▼                     ▼
        birthdays            reminders            settings
            │                     │                     │
            └─────────► sync ◄────┴─────────────────────┘
                              │
                              ▼
                          firestore
```

## Phase 1 — Core Architecture scope

Files to add:

- `lib/app/app.dart` — root widget
- `lib/app/bootstrap.dart` — bootstrap function
- `lib/app/dependencies.dart` — composition root (single Provider tree)
- `lib/core/errors/app_failure.dart` — generic failure sealed type
- `lib/core/logging/app_logger.dart` — debug/release aware logger
- `lib/core/theme/app_theme.dart` — Material 3 light theme tokens (dark deferred)
- `lib/core/config/app_config.dart` — build-time constants

Files to modify:

- `lib/main.dart` — become 6 lines: ensureInitialized → bootstrap → runApp

Behavior preserved: AuthGate still root, AuthScreen ↔ Homepage flow unchanged, all39 tests pass.
