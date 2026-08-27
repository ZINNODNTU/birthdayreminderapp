# CURRENT_ARCHITECTURE.md

## Recent Updates

### 2026-08-27 — Google-only Auth + Standardized Firestore Schema

* `AuthRepository` is `currentUser`, `authStateChanges`,
  `signInWithGoogle()`, `signOut()`. Email/password registration,
  login, and reset are removed.
* `FirebaseAuthRepository` uses `google_sign_in ^7.2.x` and validates
  `providerData.contains('google.com')` before returning the user.
* `UserProfileRepository.ensureProfile(user)` upserts
  `/users/{uid}` on every fresh sign-in. Schema:
  `uid`, `email`, `displayName`, `photoUrl`, `provider: 'google.com'`,
  `createdAt`, `updatedAt`, `lastLoginAt`, `schemaVersion: 1`.
* `BirthdayFirestoreMapper` and `BirthdayRemoteRepository` are the
  canonical converters / repository for `/users/{uid}/birthdays/{id}`.
* `firestore.rules` enforces Google-only writes; legacy
  `/birthdays/{...}` is denied.
* 22 emulator tests cover the new schema and rules.
* Local SQLite is the source of truth until Phase 5 SyncManager
  lands (currently `stash@{0}`).

The pre-existing architecture described below is still largely
accurate for everything that doesn't touch auth or cloud.

---

## Repository Overview
- **Project**: birthdayreminderapp (Flutter)
- **Git**: Single commit `6496266 Initial commit`, branch: `main`
- **Flutter SDK**: Not installed locally (environment limitation)
- **Dart SDK**: `^3.7.2` (per pubspec.yaml)
- **Single Git commit** — no CI/CD, no release history

---

## 1. Dependency Analysis (pubspec.yaml)

| Package | Version | Notes |
|--------|---------|-------|
| firebase_core | ^3.8.0 | ✅ Modern |
| firebase_auth | ^5.3.3 | ✅ Modern, but **no auth flow implemented** |
| cloud_firestore | ^5.5.0 | ✅ Modern, but used insecurely |
| intl | ^0.20.2 | ✅ Modern |
| uuid | ^4.2.2 | ✅ |
| flutter_local_notifications | ^19.2.1 | ✅ |
| timezone | ^0.10.1 | ✅ |
| image_picker | ^1.0.4 | ✅ |
| http | ^1.4.0 | ✅ |
| mime | ^1.0.4 | ✅ |
| http_parser | ^4.0.2 | ✅ |
| provider | ^6.1.1 | ✅ |
| full_calender | ^1.2.12 | ⚠️ Dead package? Verify |
| table_calendar | ^3.2.0 | ✅ |
| image | ^4.1.3 | ✅ |
| permission_handler | ^12.0.0+1 | ✅ |
| package_info_plus | ^8.3.0 | ✅ |
| path_provider | ^2.4.2 | ✅ |
| sqflite | ^2.4.2 | ✅ |
| path | ^1.9.1 | ✅ |
| flutter_contacts_service | ^0.0.3 | ⚠️ Very old (pub 0.0.3) |
| share_plus | ^11.0.0 | ✅ |
| lunar | ^1.7.5 | ✅ (used for lunar conversion) |
| csv | ^6.0.0 | ✅ |
| open_file | ^3.5.10 | ✅ |
| flutter_native_timezone | ^2.0.0 | ⚠️ Deprecated, replaced by `flutter_timezone` |
| device_info_plus | ^11.4.0 | ✅ |
| shared_preferences | ^2.5.3 | ✅ |
| flutter_timezone | ^4.1.1 | ✅ |

### Dependency Risks
- `flutter_contacts_service` ^0.0.3: Very old version, pub score poor. May break on Android 14 / iOS 17+.
- `flutter_native_timezone` ^2.0.0: Marked deprecated in pub.dev. Both `flutter_native_timezone` and `flutter_timezone` are included — redundant.
- `full_calender` ^1.2.12: Unverified package quality.

---

## 2. Current Architecture

### Directory Structure
```
lib/
├── controllers/
│   └── birthday_controller.dart      # ChangeNotifier, CRUD, notification scheduling
├── firebase_options.dart            # 🔴 HARDCODED API KEYS (SECURITY)
├── main.dart                        # App bootstrap, Firebase init
├── models/
│   └── birthday.dart                # Single model: Birthday + LunarDateTime
├── services/
│   ├── csv_export_service.dart      # CSV export with legacy permissions
│   ├── firestore_service.dart       # Global collection, no auth scoping
│   ├── gemini_service.dart          # 🔴 HARDCODED Gemini API KEY
│   ├── local_db_service.dart        # SQLite (sqflite) v1 schema, no migrations
│   └── notification_service.dart     # Local notifications, timezone handling
├── utils/
│   ├── helpers.dart                  # Avatar base64 resize, share
│   └── lunar_converter.dart          # 🔴 BROKEN — placeholder, doesn't convert
└── views/
    ├── birthday_add_edit_view.dart
    ├── birthday_detail_view.dart     # AI integration here
    ├── birthday_item.dart
    ├── birthday_list_view.dart
    ├── calendar_view.dart
    ├── contact_import.dart
    └── homepage.dart
```

### State Management
- Single `BirthdayController` extends `ChangeNotifier`
- Provided via `ChangeNotifierProvider` at root — **no DI, no use cases, no repositories**
- Controller directly calls `LocalDBService`, `FirestoreService`, `NotificationService` — tightly coupled

### Data Layer
- Local DB: SQLite via sqflite, version 1, single `birthdays` table
- No schema versioning/migration support
- Avatar stored as **Base64 string** in DB — memory/performance issue
- Cloud: Firestore `birthdays` collection (global, no per-user scoping)

### Notification
- Uses `flutter_local_notifications` + `timezone`
- Single reminder per birthday (`remindBeforeDays` + `remindTime`)
- Notification ID = `birthday.id.hashCode` — **collision risk, not stable**
- Uses `matchDateTimeComponents: dayOfMonthAndTime` for yearly recurrence — **broken for lunar birthdays**
- No reconciliation on app start/boot
- No deep-link handling for notification taps

### AI (Gemini)
- `GeminiService` hardcodes API key: `[REDACTED]`
- Direct HTTP POST to Gemini API from client
- No rate limiting, no retry, no App Check, no input validation

### Contact Import
- Uses `flutter_contacts_service` ^0.0.3
- Reads contacts with `photoHighResolution: true` — loads all photo data
- Deduplication only by name (no phone/identifier-based dedup)
- **Uploads all contact photos to local DB as base64**

### Lunar Calendar
- `lunar_converter.dart`: **Placeholder — returns same day/month instead of converting**
- `Birthday.toMap()` stores `lunarDay`, `lunarMonth`, `lunarYear` but `lunar_converter.dart` is broken
- `BirthdayDetailView` displays lunar birthday from stored values (not recalculated per year)
- Calendar view uses `lunar` package's `Lunar.fromDate()` for display — functional but inconsistent

### UI
- `ThemeData` with `Colors.teal` primarySwatch — basic Material, not Material 3
- No dark mode, no localization arb files
- UI strings hardcoded in Vietnamese in widgets
- No design tokens

---

## 3. Technical Debt

| Area | Issue |
|------|-------|
| Architecture | No separation of data/domain/presentation layers |
| State | Single controller, tightly coupled to all services |
| DI | No dependency injection, singletons created inline |
| Model | Single `Birthday` model stores everything; no domain separation |
| Repository | No repository pattern; services called directly from controller |
| Error handling | `catch (e) { print(e) }` or snackbar strings; no domain error model |
| Logging | Uses `devtools.log` with emoji; no structured logging |
| Tests | Only default `widget_test.dart` — tests counter increment (irrelevant) |
| Versioning | `1.0.0+1`, hardcoded, not read from package_info |
| Flavors | No dev/staging/prod environments |
| CI/CD | No GitHub Actions |

---

## 4. Security Issues (CRITICAL)

| Severity | Issue | Location |
|----------|-------|----------|
| 🔴 CRITICAL | Gemini API key hardcoded in client source | `lib/services/gemini_service.dart:5` |
| 🔴 CRITICAL | Firebase API keys hardcoded in client | `lib/firebase_options.dart` (all platforms) |
| 🔴 HIGH | Google API key committed in `google-services.json` | `android/app/google-services.json` |
| 🔴 CRITICAL | Firestore `birthdays` collection is global (no user scoping) | `lib/services/firestore_service.dart` |
| 🔴 CRITICAL | No App Check | Entire app |
| 🔴 HIGH | No auth required for Firestore reads/writes | `firestore_service.dart` |
| 🟡 MEDIUM | `debugShowCheckedModeBanner` only | `lib/main.dart:34` |
| 🟡 LOW | Uses `print`/`debugPrint` for error logging | Throughout services |

### Credentials Committed in Git
1. **Firebase API Keys**:
   - Web/Windows: `[REDACTED]`
   - Android: `[REDACTED]`
   - iOS/macOS: `[REDACTED]`
2. **Gemini API Key**: `[REDACTED]`
3. **google-services.json**: Contains Android API key
4. **Firebase project ID**: `birthdayreminderapp-89e7d`
5. **Firebase App ID**: `1:922005299348:android:790d58ef22da4ccee21481`

---

## 5. Bugs Found

| Bug | Location | Impact |
|-----|----------|--------|
| **Lunar converter is a placeholder** | `utils/lunar_converter.dart` | Lunar dates displayed correctly only because `Birthday` uses `lunar` package's `Lunar.fromDate`/`Lunar.fromYmd` directly. But `lunar_converter.dart` is dead/incorrect code. |
| **Only one reminder per birthday** | `Birthday` model | Can't support multiple reminders per birthday (e.g., 7 days + 3 days + 1 day before) |
| **Notification ID collision** | `notification_service.dart:90` | Uses `birthday.id.hashCode` — String.hashCode collisions possible |
| **Lunar birthday scheduling broken** | `notification_service.dart:65-67` | Converts lunar → solar **once** using `lunarBirthday.toSolarDateTime()` which uses fixed `year` stored in `LunarDateTime`. For recurring yearly reminders, it doesn't recalculate lunar date for each year. |
| **Calendar view filters by exact day+month** | `calendar_view.dart:34-39` | Lunar birthdays: `toSolarDateTime()` uses the stored lunarYear, so the date won't change year-to-year. |
| **No notification permission rationale on iOS** | `AndroidManifest.xml`, iOS Info.plist | No `NSContactsUsageDescription`, `NSCalendarsUsageDescription`, etc. |
| **Contact import sets solarBirthday to `now`** | `contact_import.dart:68` | Imported contacts get today's date as birthday — clearly a placeholder |
| **Avatar loaded as full Image.memory** | `birthday_item.dart`, `calendar_view.dart` | Base64 decoded every render — memory waste on lists |
| **No search debounce** | `birthday_list_view.dart:126-130` | `setState` on every keystroke |
| **List re-render issue** | `calendar_view.dart:183-216` | Filters birthdays up to 3 times per build — O(n) × repeated |
| **Test notification creates new BirthdayController** | `birthday_detail_view.dart:294` | `BirthdayController()` called in onPressed — creates new instance with new `_init()` |
| **No error boundaries on API calls** | `birthday_detail_view.dart:56` | Catches Exception, displays raw error string to user |

---

## 6. Current Features Inventory

### Implemented
| Feature | Status | Notes |
|---------|--------|-------|
| Thêm sinh nhật | ✅ | Manual form only |
| Sửa sinh nhật | ✅ | |
| Xóa sinh nhật | ✅ | Single delete + multi-select delete |
| Xem danh sách | ✅ | List view with search & sort |
| Xem chi tiết | ✅ | Detail view with avatar, info |
| Calendar | ✅ | TableCalendar, but lunar display is static |
| Ngày dương | ✅ | Solar birthday |
| Ngày âm | ✅ | Lunar birthday (using `lunar` package) |
| Recurring birthday | ✅ | `repeatAnnually` flag |
| Notification | ⚠️ Partial | Single reminder, broken for lunar |
| Import contacts | ✅ | But sets birthday to `now` |
| Avatar | ✅ | Base64 (performance issue) |
| Relationship | ✅ | |
| Nickname | ✅ | |
| Note | ✅ | |
| CSV export | ✅ | |
| Local database | ✅ | SQLite |
| Firestore backup | ✅ | But global collection, insecure |
| AI gift suggestions | ✅ | Hardcoded key |
| AI wish suggestions | ✅ | Hardcoded key |
| Vietnamese locale | ⚠️ | `vi` formatting but no arb files |
| Share birthday | ✅ | `share_plus` |

### Not Implemented
| Feature | Status |
|---------|--------|
| Authentication (any kind) | ❌ |
| Per-user Firestore | ❌ |
| App Check | ❌ |
| Dark mode | ❌ |
| Localization arb | ❌ |
| Deep linking | ❌ |
| Cloud sync (proper) | ❌ |
| Multiple reminders | ❌ |
| Settings screen | ❌ |
| Account management | ❌ |
| Subscription/monetization | ❌ |
| Error handling model | ❌ |
| Structured logging | ❌ |
| Crashlytics | ❌ |
| Analytics | ❌ |
| Remote Config | ❌ |
| CI/CD | ❌ |
| Tests beyond default | ❌ |
| Multiple environments | ❌ |
| Accessibility (semantics) | ❌ |
| Responsive (tablet/web) | ❌ |
| Notification reconciliation | ❌ |
| Notification deep link | ❌ |
| CSV import | ❌ (commented out) |
| Data export (GDPR) | ❌ |
| Privacy policy / terms | ❌ |

---

## 7. Platform Configuration Status

### Android
- `minSdk = 23`, `targetSdk = flutter.targetSdkVersion` (likely 35)
- Permissions in AndroidManifest.xml:
  - `WRITE_EXTERNAL_STORAGE`, `READ_EXTERNAL_STORAGE`, `MANAGE_EXTERNAL_STORAGE` — legacy, needs update for API 33+
  - `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`
  - `READ_CONTACTS`, `WRITE_CONTACTS`
  - `CAMERA` (for image picker)
  - `RECEIVE_BOOT_COMPLETED`
- **Missing**: `USE_EXACT_ALARM` for Android 14+, `NEARBY_WIFI_DEVICES`
- **Missing**: iOS-specific permissions entirely

### iOS
- Info.plist: Minimal config, no usage descriptions
- **Missing**: `NSContactsUsageDescription`, `NSCalendarsUsageDescription`, `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSNotificationUsageDescription`, `NSLocationWhenInUseUsageDescription`

### Missing Platform Configuration
- No notification channel configuration
- No background fetch handler
- No App Check provider configuration
- No Google Services configuration for iOS

---

## 8. Key Design Violations (Current vs Production Standards)

| Current | Required |
|---------|----------|
| No auth | AuthGate with anonymous + email + Google + Apple |
| Global Firestore collection | Per-user `/users/{uid}/birthdays/{id}` |
| Hardcoded API keys | Environment-based, backend-proxied AI |
| Single reminder | Multiple reminder rules |
| Lunar calculated once | Recalculate per target year |
| Base64 avatar in DB | File-based avatar with cached network image |
| No DI | Proper dependency injection |
| UI logic in widgets | Use case + repository pattern |
| No tests | Unit + widget + integration tests |
| No CI/CD | GitHub Actions |
| No dark mode | Light/dark/system themes |
| No localization | arb files for vi/en |
| Default Material | Material 3 design system |
