# Firestore Schema

## Project

```
projectId: birthdayreminderapp-89e7d
```

## Path layout

```
/users/{uid}                                # profile document
/users/{uid}/birthdays/{birthdayId}         # birthday subcollection
```

> The legacy `/birthdays/{id}` top-level collection is **denied** at the
> security-rules level. Old callers will get a permission-denied error
> and must be migrated to the per-user subcollection.

## `/users/{uid}` — profile

| Field          | Type            | Notes                                           |
| -------------- | --------------- | ----------------------------------------------- |
| `uid`          | string          | MUST match the document id                      |
| `email`        | string          | from Firebase Auth                              |
| `displayName`  | string?         | from Firebase Auth                              |
| `photoUrl`     | string?         | from Firebase Auth                              |
| `provider`     | string          | MUST be `'google.com'`                          |
| `createdAt`    | timestamp       | server timestamp; immutable on update           |
| `updatedAt`    | timestamp       | server timestamp                                |
| `lastLoginAt`  | timestamp       | refreshed on every sign-in                      |
| `schemaVersion`| int             | MUST be `1`                                     |

`UserProfileRepository.ensureProfile()` upserts this document on every
fresh Google sign-in. Updates only touch `email`, `displayName`,
`photoUrl`, `lastLoginAt`, `updatedAt`. `createdAt` is preserved.

## `/users/{uid}/birthdays/{birthdayId}` — birthday

| Field           | Type                          | Notes                                 |
| --------------- | ----------------------------- | ------------------------------------- |
| `id`            | string                        | MUST match the document id            |
| `name`          | string                        | non-empty                             |
| `nickname`      | string?                       |                                       |
| `gender`        | string?                       |                                       |
| `relationship`  | string?                       |                                       |
| `calendarType`  | `'solar' \| 'lunar'`          |                                       |
| `solarBirthday` | timestamp                     |                                       |
| `lunar`         | `{day,month,year,isLeap}`\|null |                                       |
| `note`          | string?                       |                                       |
| `reminder`      | object                        | see below                             |
| `createdAt`     | timestamp                     |                                       |
| `updatedAt`     | timestamp                     |                                       |
| `deletedAt`     | timestamp?                    | null while active                     |
| `schemaVersion` | int                           | MUST be `1`                           |

### `reminder`

| Field            | Type    | Notes                                  |
| ---------------- | ------- | -------------------------------------- |
| `enabled`        | bool    |                                        |
| `daysBefore`     | int     | ≥ 0                                    |
| `hour`           | int     | 0..23                                  |
| `minute`         | int     | 0..59                                  |
| `repeatAnnually` | bool    |                                        |

### Lunar leap months

SQLite schema v2 does not persist leap-month state, so the cloud
schema v1 hard-codes `isLeapMonth: false`. When the local schema
upgrades to v3, bump cloud `schemaVersion` and include the real flag.

## Local vs cloud schema

The on-device `Birthday` model and the Firestore document are mapped
in `lib/features/birthdays/data/birthday_firestore_mapper.dart`. Do
not collapse the two: the SQLite model is denormalised for indexing,
the cloud model is normalised for security-rule validation.

## Security rules

`firestore.rules` enforces:

* Only the owning user can read/write their profile and birthdays.
* Only Google-authenticated users can create profiles.
* Profile `provider` must be `google.com` and `uid` must match the path.
* Birthday document `id` must match the path.
* Reminder `hour` is 0..23, `minute` is 0..59, `daysBefore` ≥ 0.
* `createdAt` is immutable.
* `/birthdays/{...}` is denied at the catch-all level.

22 emulator tests cover all rules (see
`firebase-tests/firestore.rules.test.js`).

## SyncManager (Phase 5)

Sync is intentionally **not** wired in this commit. The Phase 5
SyncManager lives in `stash@{0}` and will be re-applied on top of
this schema in a follow-up commit. Until then, cloud sync is
disabled — the local SQLite store is the source of truth.
