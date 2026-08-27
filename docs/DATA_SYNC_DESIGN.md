# Data Sync Design — Phase 2

This document defines the **future** cloud sync architecture. It does not
implement sync — that lands in Phase 5. The metadata it describes is already
on disk so sync can be added without another schema bump.

## Source of truth

* **Local SQLite is the immediate source of truth.** Every read and write
  the UI does goes through `BirthdayRepository` → `LocalBirthdayRepository`
  → `LocalDbService`.
* **Firestore is a remote replica.** Owned rows live under
  `/users/{uid}/birthdays/{birthdayId}`. There is no longer any global
  `/birthdays/{id}` collection.

## Ownership and identity

* `ownerUid` is null for local-only rows.
* When a Firebase user signs in, rows that were created while in local
  mode stay local. They are NOT auto-uploaded. Promoting them to a remote
  account is a Phase 5 feature.
* `ownerUid` MUST be a real Firebase UID. Fake values such as `guest`,
  `local`, or `anonymous` are forbidden — Firestore rules would reject
  them anyway because of the per-user scoping.

## Sync-ready metadata (already on disk in Phase 2)

| Column         | Purpose                                        |
| -------------- | ---------------------------------------------- |
| `created_at`   | First write time (backfilled with migration time for v1 rows). |
| `updated_at`   | Last write time. Repository bumps this on every mutation. |
| `deleted_at`   | Soft-delete tombstone. Not yet used by the UI; reserved for Phase 5. |
| `sync_status`  | One of `localOnly`, `pendingUpload`, `synced`, `pendingDelete`, `syncError`. |
| `owner_uid`    | Firebase UID, or null.                         |
| `schema_version` | Birthday shape version. Currently `2`.       |

The metadata is mandatory going forward but not yet surfaced in the UI.

## Local-mode rules

* `Local-only birthdays are NEVER touched by Firestore.` The cloud buttons
  in the drawer are gated behind `AppSessionMode.authenticated`; otherwise
  they show a friendly "Đăng nhập để sử dụng tính năng đồng bộ đám mây"
  snackbar and never construct `FirestoreService`.
* `Login from local mode MUST NOT delete local birthdays.` Sign-in is a
  pure auth event; the SQLite database is untouched.
* `Logout MUST NOT delete local birthdays.` The local-mode flag is cleared
  so the next launch returns to `AuthScreen`, but the data stays.

## Conflict resolution (future)

Last-writer-wins keyed on `updatedAt`, then on `id` to break ties. If the
remote row is newer than the local one, remote wins and the local copy is
discarded (with a one-shot toast). If local is newer, local wins and the
remote copy is overwritten. Ties resolve in favour of the authenticated
device.

## Phase 3 — Google-only auth + standardized schema (2026-08-27)

* Removed email/password registration, login, and reset. The only
  sign-in path is Google. See `docs/AUTHENTICATION.md`.
* Standardized the canonical Firestore schema. Profile lives at
  `/users/{uid}` and birthdays at
  `/users/{uid}/birthdays/{id}`. See `docs/FIRESTORE_SCHEMA.md`.
* `BirthdayRemoteRepository` + `BirthdayFirestoreMapper` are the
  cloud-side equivalent of the SQLite repository. UI code must not
  reach for `FirebaseFirestore` directly.
* No local→cloud auto-upload yet. The SyncManager in
  `stash@{0}` (Phase 5) is the gate for that.

## Phase 2 → Phase 5 hand-off

When Phase 5 starts it will introduce:

* `SyncManager` that consumes `Stream<List<Birthday>>` from
  `LocalBirthdayRepository` and reconciles with the Firestore replica.
* Network availability gating (no upload while offline).
* Background upload retry with exponential back-off.
* UI: a sync indicator in the app bar; conflicts surfaced as a list.

The repository abstraction added in Phase 2 means none of that work has
to touch the UI layer — only the data layer and the dependency wiring.
