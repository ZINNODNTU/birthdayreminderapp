# Releases

This document tracks official releases of Birthday Reminder.

The runtime updater reads **GitHub Releases** as the source of truth.
This file is human-maintained documentation only.

## Release Table

| Version | Build | Channel | Status | Signing | Updater |
|---|---:|---|---|---|---|
| 1.0.0 | 1 | Stable | Legacy | Android debug | Legacy |
| 1.0.1 | 2 | Migration Bridge | Released | Legacy bridge only | Backup/restore and reinstall guidance |
| 2.0.0 | 3 | Stable | Prepared | First permanent production signer | Reinstall boundary |

Notes:

- `v1.0.0` has an APK but no structured metadata or SHA companion asset.
- `v1.0.1` is released with full-fidelity backup/restore for the signer boundary.
- `v2.0.0` is the first permanently signed release and requires a one-time reinstall.
- `v2.0.1`, `v2.1.0`, `v3.0.0`, and every later release must reuse this same permanent key. Never generate a key per release.

## Legacy v1.0.0 and signing migration

`v1.0.0` uses Android debug signing:

- SHA-1: `ED:CD:C4:C2:59:0B:81:F5:C0:80:5F:0E:08:77:FB:5E:35:09:6E:D1`
- SHA-256: `BD:24:C3:98:18:B6:F2:D4:06:0C:DC:F7:14:E2:8D:AE:F9:4F:24:5D:28:B1:72:1A:6F:06:77:E7:B7:3B:0D:A6`

A permanent production certificate cannot update `v1.0.0` in place. Current
CSV export has no restore path, so Local Mode migration remains blocked.
Recommended planning path: transitional `v1.0.1` with full-fidelity migration
tools under the legacy signer, then `v2.0.0` with the permanent signer. See
[`SIGNING_MIGRATION.md`](SIGNING_MIGRATION.md). No version is selected or
published yet.

## Signing Migration Note

Android blocks in-place updates when the signing certificate changes.

If `1.0.0` is signed with the legacy/debug certificate and `1.0.1` is signed
with a different production certificate, Android will **refuse** to install
`1.0.1` over `1.0.0`. Users would need to uninstall first, which destroys
local data.

A signing migration plan is required before the self-update feature can be
called production-ready for existing users.
