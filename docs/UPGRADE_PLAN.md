# UPGRADE_PLAN.md

## Executive Summary

The current Birthday Reminder app is a **single-commit Flutter prototype** with:
- Hardcoded secrets (Gemini API key, Firebase API keys) in client source
- Global Firestore collection (no per-user isolation)
- No authentication
- Broken lunar calendar scheduling (lunar date calculated once, not per year)
- Single reminder per birthday (no multi-rule support)
- No tests, no CI/CD, no dark mode, no localization arb files
- No Material 3 design system
- No error handling model
- No structured logging or observability

**This migration uses a phased approach (Phase 0–7) to progressively upgrade to production-grade while preserving all existing features.**

---

## Phase 0: Audit & Security (CURRENT)

### Goals
1. Complete repository audit
2. Remove all hardcoded secrets from client source
3. Set up `.env.example` for non-secret configuration
4. Create `firestore.rules` with per-user data isolation
5. Create `docs/SECURITY_ACTION_REQUIRED.md`
6. Update `.gitignore`
7. Set up Firebase project configuration (google-services.json placeholder, iOS config)

### Security Actions — IN PROGRESS
- [x] Audit complete — 3 API keys found in `gemini_service.dart`, 5 in `firebase_options.dart`, 1 in `google-services.json`
- [ ] **Gemini API key**: `[REDACTED]` — must be **rotated immediately** on Google Cloud Console
- [ ] **Firebase API keys**: Must be rotated on Firebase Console
- [ ] Remove all keys from `lib/firebase_options.dart` — use environment-based or Firebase CLI
- [ ] Remove Gemini key from `lib/services/gemini_service.dart` — route through Firebase Functions
- [ ] Create `docs/SECURITY_ACTION_REQUIRED.md`

### Technical Tasks
- [ ] Create `.env.example` with non-secret config (Firebase project ID, API endpoints, feature flags)
- [ ] Update `.gitignore` to exclude `.env`, `lib/env/`, `functions/.env`, `firebase-debug.log`, `.firebaserc`
- [ ] Create `firestore.rules` with per-user isolation
- [ ] Add iOS permissions to `Info.plist`
- [ ] Update Android permissions for API 33+ (remove `MANAGE_EXTERNAL_STORAGE`, use `READ_MEDIA_IMAGES`)
- [ ] Update `AndroidManifest.xml` for Android 14 exact alarm (`USE_EXACT_ALARM`)
- [ ] Verify `google-services.json` — note: Google API keys in this file are Firebase config, not secrets to rotate via backend, but still committed

### Tests
- [ ] `flutter analyze` passes (after removing hardcoded keys)
- [ ] `flutter test` passes

---

## Phase 1: Core Architecture

### Goals
- Create core foundation: config, constants, errors, logging, theme, utils, widgets
- Set up dependency injection
- Implement structured routing
- Create design system (Material 3, design tokens)

### Technical Tasks
- [ ] Create `lib/core/` directory with:
  - `config/` — environment configuration
  - `constants/` — app constants
  - `errors/` — `AppFailure` hierarchy (`NetworkFailure`, `DatabaseFailure`, `AuthenticationFailure`, `PermissionFailure`, `NotificationFailure`, `SyncFailure`, `AIServiceFailure`, `UnknownFailure`)
  - `logging/` — structured logging (debug vs production logger)
  - `security/` — App Check setup, input validation
  - `theme/` — `AppColors`, `AppSpacing`, `AppRadius`, `AppTypography`, `AppShadows`, `AppTheme`
  - `utils/` — date utils, validators, extensions
  - `widgets/` — reusable widgets (app bar, error states, loading states)
- [ ] Create `lib/app/` directory:
  - `app.dart` — MaterialApp with theme, locale, routing
  - `router/` — GoRouter configuration with all routes
  - `bootstrap/` — splash + bootstrap + AuthGate
  - `dependencies/` — service locator (get_it)
- [ ] Migrate from Provider to Riverpod (incremental, feature-by-feature)
- [ ] Add `get_it` and `go_router` dependencies
- [ ] Create `lib/features/` directory structure (data/domain/presentation for each feature)

### Tests
- [ ] Unit tests for AppFailure hierarchy
- [ ] Unit tests for validators

---

## Phase 2: Birthday Domain

### Goals
- Refactor `Birthday` model into proper domain model: `Person`, `Birthday`, `ReminderRule`, `Relationship`, `CalendarType`, `SyncMetadata`
- Implement `BirthdayDateCalculator` (independent of UI)
- Support **multiple reminders per birthday**
- Proper solar/lunar calendar engine with per-year lunar recalculation
- SQLite database migration with versioning

### Technical Tasks
- [ ] Create domain models:
  - `Person` (id, name, avatarPath, gender, nickname, relationship, note, syncMetadata)
  - `Birthday` (id, personId, solarDay, solarMonth, solarYear, calendarType, lunarDay, lunarMonth, isLeapMonth, reminderRules)
  - `ReminderRule` (id, birthdayId, remindBeforeDays, remindTime, enabled)
  - `SyncMetadata` (ownerId, createdAt, updatedAt, deletedAt, syncStatus, schemaVersion)
- [ ] Create `BirthdayDateCalculator`:
  - `nextSolarBirthday(birthDate, referenceDate)` — handles Feb 29
  - `nextLunarBirthday(lunarDay, lunarMonth, isLeapMonth, targetYear)` — recalculates lunar per year
  - `solarToLunar(date)` and `lunarToSolar(day, month, year, isLeapMonth)` using `lunar` package
  - Feb 29 policy configuration (28/02 or 01/03)
- [ ] Create SQLite migration:
  - Version 2: Add `owner_id`, `created_at`, `updated_at`, `deleted_at`, `sync_status`, `schema_version`
  - Version 3: Add `reminder_rules` table (foreign key to birthdays)
  - Version 4: Add `people` table
  - Migrate existing data from v1 schema
- [ ] Write comprehensive unit tests for date calculator:
  - Solar: Feb 29, timezone boundaries, year transition
  - Lunar: leap months, year transition, invalid dates, per-year recalculation

### Tests
- [ ] Unit tests for `BirthdayDateCalculator` (15+ test cases)
- [ ] Unit tests for lunar conversion
- [ ] Unit tests for next birthday calculation
- [ ] Unit tests for reminder calculation
- [ ] Database migration tests

---

## Phase 3: Notification Engine

### Goals
- Stable, persisted notification IDs
- Support multiple reminders per birthday
- Notification reconciliation on app start/boot
- Deep link handling for notification taps

### Technical Tasks
- [ ] Create `NotificationEngine` (domain-level):
  - Persisted notification ID mapping (birthdayId + ruleId → stable int)
  - Support multiple reminders per birthday
  - Yearly recurrence with proper lunar recalculation
  - Timezone change handling
  - Device reboot / app update / permission change handling
  - Reconciliation: compare DB expected schedules ↔ OS scheduled notifications
  - Deep link payload: `{birthdayId: "...", personId: "..."}`
- [ ] Implement `androidScheduleMode: exactAllowWhileIdle` with proper Android 12+ permission handling
- [ ] Handle iOS notification limitations (time-sensitive requests for exact reminders)
- [ ] Add `WORK_MANAGER` / background task for reconciliation
- [ ] Implement notification tap → deep link to birthday detail

### Tests
- [ ] Unit tests for notification ID generation
- [ ] Unit tests for notification reconciliation logic

---

## Phase 4: Authentication & Cloud

### Goals
- Production-grade auth with Firebase Authentication
- Per-user Firestore data isolation
- Offline-first architecture (local → cloud sync)
- App Check enforcement

### Technical Tasks
- [ ] Implement `AuthGate` (splash → bootstrap → AuthGate):
  - Anonymous auth as default (auto-create account)
  - Email + Password (sign in, register, forgot password, email verification)
  - Google Sign-In
  - Apple Sign-In (iOS)
  - Sign out, delete account, re-authentication for sensitive actions
  - Session persistence
- [ ] Migrate Firestore to per-user structure:
  - `/users/{uid}/birthdays/{birthdayId}`
  - `/users/{uid}/preferences/{document}`
  - `/users/{uid}/devices/{deviceId}`
- [ ] Create `firestore.rules` with `request.auth != null` and `request.auth.uid == resource.data.ownerId`
- [ ] Enable App Check (Debug provider for dev, Play Integrity for Android, DeviceCheck for iOS)
- [ ] Implement offline-first repository pattern:
  - `BirthdayRepository` (domain layer)
  - `LocalDataSource` (SQLite)
  - `RemoteDataSource` (Firestore)
  - Optimistic writes, retry queue, tombstones, conflict resolution, idempotent sync
- [ ] Implement sync:
  - Local mutations queued when offline
  - Background sync when online
  - Conflict resolution (last write wins or merge)
  - Cloud backup & restore

### Tests
- [ ] Integration tests for Firestore security rules (emulator)
- [ ] Unit tests for sync conflict resolution
- [ ] Unit tests for repository (local + remote)

---

## Phase 5: UI/UX

### Goals
- Full Material 3 design system
- Premium consumer app UX
- Auth-aware navigation
- All existing screens redesigned

### Technical Tasks
- [ ] Create `lib/features/settings/` with full settings screen:
  - General: language, theme, timezone, first day of week
  - Reminder: default days, default time, sound, vibration, quiet hours
  - Data: backup, restore, export CSV, import, sync status
  - Privacy: analytics consent, data export, delete cloud data, delete account
  - About: version (from package_info), privacy policy, terms, licenses, feedback
- [ ] Redesign Home Dashboard:
  - Greeting (based on time of day)
  - Upcoming birthday card (avatar, name, relationship, date, age, days remaining, send wish, gift ideas)
  - This week preview
  - This month preview
  - Calendar preview
  - Quick actions (Add, Import, Calendar, AI Wish)
- [ ] Redesign Birthday List:
  - Debounced search
  - Sort (upcoming first, name, age)
  - Filter (relationship, calendar type, month, favorites)
  - Favorites (star toggle)
  - Smooth performance with large lists (ListView.builder with const widgets, itemExtent)
- [ ] Redesign Birthday Detail:
  - Hero animations for avatar
  - All fields displayed in cards
  - AI gift & wish suggestions
  - Edit button / delete with confirmation
- [ ] Upgrade Contact Import:
  - Permission explanation screen
  - Detect birthdays from contacts (birthday fields, not just name)
  - Multi-signal deduplication (contact ID, normalized name, birthday)
  - Preview before import
  - **No uploading of entire contact book to server**
- [ ] Upgrade Add/Edit Birthday:
  - Multiple reminder rules (add/remove rule cards)
  - Lunar date picker when lunar mode selected
  - Avatar: file-based storage (not base64)

### Tests
- [ ] Widget tests for home dashboard (loading, empty, success states)
- [ ] Widget tests for birthday list (search, sort, filter)
- [ ] Widget tests for birthday form (validation, save)
- [ ] Widget tests for error/empty/loading states

---

## Phase 6: AI Assistant

### Goals
- Secure AI backend via Firebase Cloud Functions
- Gift suggestion and wish generation as structured features
- Rate limiting, quotas, cost protection
- Graceful degradation

### Technical Tasks
- [ ] Create Firebase Cloud Functions:
  - `aiGiftSuggestions` — callable function
  - `aiWishSuggestions` — callable function
  - Verify App Check in functions
  - Verify Firebase Auth
  - Input validation (name length, relationship, tone enum)
  - Rate limiting (per-user quota)
  - Timeout and retry with exponential backoff
  - Cost protection (max tokens, daily spend cap via budget alerts)
  - Structured error responses (`{error: {code, message}}`)
  - Request logging without PII
- [ ] Create `AiAssistantService` in Flutter:
  - Calls Cloud Functions, not Gemini API directly
  - Handles auth token (passed automatically by callable functions)
  - Graceful degradation: show offline message if backend unavailable
  - No dependency on AI for core birthday features
- [ ] Create `AI Assistant` feature screen:
  - Wish Generator: input name, relationship, age, personality, tone, occasion, language, length
  - Gift Assistant: input relationship, age range, interests, budget, occasion
  - Tone options: thân mật, hài hước, tình cảm, trang trọng, Gen Z, ngắn gọn

### Tests
- [ ] Unit tests for AI response parsing
- [ ] Unit tests for AI error handling (rate limit, timeout, malformed response)

---

## Phase 7: Production

### Goals
- Full test suite passing
- CI/CD with GitHub Actions
- Crashlytics, Analytics, Remote Config
- App flavors (dev/staging/prod)
- Release documentation
- Privacy documentation

### Technical Tasks
- [ ] Implement full test suite:
  - Unit: 80%+ coverage on domain layer
  - Widget: all major screens
  - Integration: login → add → edit → schedule → search → delete; offline → create → reconnect → sync
- [ ] Set up GitHub Actions:
  - PR: checkout → setup Flutter → pub get → format check → analyze → test
  - Main/tag: tests → build → artifact
- [ ] Integrate:
  - Firebase Crashlytics
  - Firebase Analytics (privacy-conscious, no PII)
  - Firebase Remote Config
- [ ] Set up Flavors:
  - Development (dev Firebase project, debug logging)
  - Staging (staging Firebase project, production-like)
  - Production (prod Firebase project, Crashlytics)
- [ ] Update `pubspec.yaml`:
  - Proper description (not "A new Flutter project")
  - Version from CI/CD
- [ ] Create production README.md
- [ ] Create `docs/PRIVACY_DATA_FLOW.md`
- [ ] Create `docs/SECURITY_ACTION_REQUIRED.md` (credentials to rotate)

### Tests
- [ ] CI pipeline passes all checks
- [ ] Integration tests pass on emulator
- [ ] `dart format .` clean
- [ ] `flutter analyze` clean (no errors/warnings)
- [ ] `flutter test` all pass

---

## Priority Order (Risk Mitigation)

1. **Remove hardcoded secrets** (Phase 0) — security P0
2. **Firestore rules + App Check** (Phase 0/4) — data safety P0
3. **Per-user data isolation** (Phase 4) — correctness P0
4. **Offline-first architecture** (Phase 4) — reliability
5. **Existing feature compatibility** (all phases) — don't break features
6. **UI/UX** (Phase 2/5) — user experience
7. **Performance** (Phase 3/7) — optimization
8. **Testability** (Phase 7) — maintenance
9. **Maintainability** (all phases) — long-term quality
10. **Monetization** (Phase 6+) — future revenue

---

## Migration Strategy

- **No big-bang rewrite**: Each phase builds on the previous, features preserved
- **Schema migration**: DB version 1 → 2 → 3 → 4 with proper migration code (never delete DB)
- **Provider → Riverpod**: Incremental migration, feature by feature
- **Single reminder → Multiple reminders**: Backfill existing birthdays with one reminder rule
- **Base64 avatar → File storage**: Migrate on next save; keep reading old base64 for backward compat
- **Global Firestore → Per-user**: Migration script or manual re-upload for existing users

---

## Expected Deliverables

| Phase | Deliverables |
|-------|-------------|
| Phase 0 | CURRENT_ARCHITECTURE.md, UPGRADE_PLAN.md, SECURITY_ACTION_REQUIRED.md, firestore.rules, .env.example, .gitignore update, iOS permissions, Android permission fixes |
| Phase 1 | core/ modules, DI, routing, theme, error model, logging |
| Phase 2 | Domain models, BirthdayDateCalculator, DB migration, unit tests |
| Phase 3 | NotificationEngine, stable IDs, reconciliation, deep links, tests |
| Phase 4 | Auth (AuthGate, all providers), Firestore rules, offline sync, App Check |
| Phase 5 | Settings screen, Home dashboard, List, Detail, Contacts, Add/Edit |
| Phase 6 | Cloud Functions, AI Assistant feature, tests |
| Phase 7 | Full test suite, GitHub Actions, Crashlytics, Analytics, flavors, README |
