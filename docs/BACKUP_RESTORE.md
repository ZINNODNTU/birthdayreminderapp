# Full-fidelity backup and restore

## Format
`BirthdayReminder-Backup-YYYYMMDD-HHmmss.zip`, schema version 1.

Entries: `manifest.json`, `birthdays.json`, `settings.json`, and `photos/<birthday-id>.jpg`. The manifest records app/build, SQLite and Birthday schema versions, counts, creation time, and SHA-256 for every payload file. Absolute device paths are never canonical data.

## Included
Every persisted Birthday field: identity, names, solar/lunar dates, calendar type, gender, relationship, note, reminder configuration, photo bytes, timestamps, tombstones, sync status, owner metadata, and Birthday schema version. Portable preferences use an explicit allowlist: theme, locale, and default reminder preferences.

## Excluded
Firebase/Google authentication data, OAuth/Bearer tokens, secure storage, AI API configuration, caches, update-check state, runtime notification fingerprints, installation IDs, credentials, and GitHub/Firebase secrets.

## Validation and security
Restore validates the entire bounded archive before mutation: ZIP structure, schema, required JSON, strict fields, duplicate IDs, dates/enums, canonical paths, SHA-256, maximum archive/expanded/JSON/photo/count limits. Traversal, absolute, and drive-letter paths are rejected. A bad photo is omitted with a warning; Birthday data remains available.

## Restore behavior
Default is MERGE. Backup replaces the same ID only when its `updatedAt` is newer. Local newer/equal data is retained. Missing timestamps become conflicts. REPLACE requires explicit UI confirmation. SQLite-backed restore uses one transaction; settings apply only after database success.

Signing-migration mode preserves visible data and tombstones while normalizing records to `localOnly` and clearing `ownerUid`. This prevents restored Local Mode data from being uploaded into an unrelated authenticated account. Authentication happens again after reinstall.

## Migration use
The future v1.0.1 bridge remains signed by the legacy signer and provides this backup. Keep the ZIP outside app-private storage. After installing v2.0.0 with the permanent signer, select the ZIP and review the restore preview before applying it.

## Limits
Archive 250 MiB; expanded content 500 MiB; 5,000 entries; JSON 20 MiB each; photo 5 MiB; 10,000 Birthdays. Current schema supports v1 and rejects unknown future schemas clearly.
