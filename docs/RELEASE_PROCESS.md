# Release Process

This document describes how to publish a new release of Birthday Reminder.

The app is distributed as an APK via GitHub Releases (not Google Play).

## 1. Prerequisites

- Local Flutter SDK matches the project-tested baseline (Flutter 3.47.1).
- Android SDK installed.
- GitHub repository access with permission to push tags and create releases.
- The following GitHub Actions secrets configured via:
  **Repository → Settings → Secrets and variables → Actions → New repository secret**
  - `ANDROID_KEYSTORE_BASE64`
  - `ANDROID_KEYSTORE_PASSWORD`
  - `ANDROID_KEY_ALIAS`
  - `ANDROID_KEY_PASSWORD`
  - `ANDROID_RELEASE_CERT_SHA256`

Never commit secret values, `android/key.properties`, keystores, `.env` files,
or private keys. The workflow fails closed when any required secret is absent.

The signing keystore must be **stable** — changing it requires a manual
uninstall/install migration for existing users.

## A. First permanent signing setup

The public `v1.0.0` APK is signed by the local Android debug certificate
(`C=US, O=Android, CN=Android Debug`). Do not promote that debug key to the
permanent production key automatically. A new permanent key breaks direct
update-in-place from `v1.0.0`; affected users need a one-time documented
uninstall/reinstall or an intentionally designed migration.

Create the permanent key manually and store it outside this repository:

```powershell
keytool -genkeypair `
  -keystore "D:\secure-backup\birthday-reminder-release.jks" `
  -alias birthday-reminder-release `
  -keyalg RSA -keysize 4096 -sigalg SHA256withRSA `
  -validity 10000
```

Use strong unique passwords. Keep at least two encrypted backups under
separate control. Losing this key permanently blocks future update-in-place.

Inspect the chosen certificate without exposing private material:

```powershell
keytool -list -v `
  -keystore "D:\secure-backup\birthday-reminder-release.jks" `
  -alias birthday-reminder-release
```

Add its SHA-1 and SHA-256 fingerprints to the existing Firebase Android app:
`com.zinnodntu.birthdayreminderapp`. Do not remove debug fingerprints.
Download refreshed Firebase configuration only when Firebase requires it.

Convert the chosen keystore for GitHub Actions; do not run this against a key
unless its owner intentionally approves secret provisioning:

```powershell
[Convert]::ToBase64String(
  [IO.File]::ReadAllBytes("D:\secure-backup\birthday-reminder-release.jks")
) | Set-Clipboard
```

Create these repository Actions secrets without committing their values:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_RELEASE_CERT_SHA256` (64 hexadecimal characters; separators optional)

The workflow temporarily materializes `android/release.keystore` and
`android/key.properties`. Both paths are ignored. Release Gradle tasks fail
when any signing property is missing; there is no debug-signing fallback.

## B. Subsequent release process

1. Retrieve the same permanent keystore from secure storage.
2. Confirm its SHA-256 equals `ANDROID_RELEASE_CERT_SHA256`.
3. Keep all five GitHub secrets unchanged unless credentials rotate without
   changing the certificate.
4. Bump `version` and build number, then run the checks below.
5. Push the matching tag only after review. The workflow builds, verifies the
   signer, computes SHA-256, then creates the release.
6. Never generate a new key for routine releases.

## Signing migration

### Legacy v1.0.0

`v1.0.0` uses the Android debug certificate:

- DN: `C=US, O=Android, CN=Android Debug`
- SHA-1: `ED:CD:C4:C2:59:0B:81:F5:C0:80:5F:0E:08:77:FB:5E:35:09:6E:D1`
- SHA-256: `BD:24:C3:98:18:B6:F2:D4:06:0C:DC:F7:14:E2:8D:AE:F9:4F:24:5D:28:B1:72:1A:6F:06:77:E7:B7:3B:0D:A6`

The stable release workflow explicitly rejects this SHA-256. Debug signing stays
development-only.

The current app can export birthday records to CSV, but has no matching CSV or
JSON restore/import path. Contact import is not backup restoration. CSV also
omits photos and synchronization metadata. Local Mode migration is therefore
**blocked**: uninstalling `v1.0.0` normally deletes SQLite data.

Authenticated synchronization restores birthday domain fields, reminders,
photos, and cloud tombstones. It does not establish restoration of local
preferences/settings; cloud restore coverage is **partial**.

Recommended transition:

1. Build a migration release such as `v1.0.1`, signed once with the legacy
   debug certificate, only after implementing tested full-fidelity export and
   import plus clear migration warnings.
2. Require users to export before uninstalling the legacy app.
3. Begin permanent signing at `v2.0.0`. The major version communicates the
   one-time reinstall boundary more clearly than `v1.1.0`.
4. Never use the legacy signer for stable production releases after migration.

No migration version or tag is selected or created by this document.

Optional schema-version-1 metadata fields can describe the boundary because
the current parser ignores unknown fields safely:

```json
{
  "requiresReinstall": true,
  "migrationMessage": "Phiên bản này sử dụng chữ ký phát hành mới. Hãy sao lưu dữ liệu Local Mode trước khi cài đặt lại."
}
```

Before publishing such metadata, add explicit parser/model/UI support and tests.
When `requiresReinstall` is true, the updater must not invoke normal APK install.
It should show **Yêu cầu cài đặt lại**, describe the new security signature,
and link to truthful backup/migration instructions. Do not show a backup button
until full-fidelity backup and restore actually exist.

## 2. Pre-release checks (local)

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

All must pass before tagging.

## 3. Bump version

Edit `pubspec.yaml`:

```yaml
version: 1.0.1+2
```

- Semantic version: `MAJOR.MINOR.PATCH`
- Build number: monotonically increasing integer.

Update `docs/RELEASES.md` to add the new row.

## 4. Commit

```bash
git add .
git commit -m "chore(release): prepare v1.0.1"
```

## 5. Tag

The tag **must** match the semantic version in `pubspec.yaml`.

```bash
git tag v1.0.1
```

Verify locally:

```bash
pwsh -File scripts/release/verify_version.ps1 -Tag v1.0.1
```

## 6. Push

```bash
git push origin main
git push origin v1.0.1
```

Pushing the tag triggers `.github/workflows/release.yml`.

## 7. Workflow stages (automated)

The workflow runs in this order and **stops on any failure**:

1. `flutter pub get`
2. `dart format` check
3. `flutter analyze`
4. `flutter test`
5. Tag/pubspec version validation
6. Signing secrets present check (no fallback to debug)
7. Reject the known legacy debug SHA-256 before materializing signing input
8. Materialize keystore from base64 secret
9. `flutter build apk --release`
10. Verify signer SHA256 matches `ANDROID_RELEASE_CERT_SHA256`
11. Reject the built APK if it uses the known legacy debug certificate
12. Rename APK → `BirthdayReminder-vX.Y.Z.apk`
13. Generate `BirthdayReminder-vX.Y.Z.apk.sha256`
14. Generate `release-metadata.json`
15. Create GitHub Release and upload assets

## 8. Manual override

`workflow_dispatch` is also enabled and requires a `tag` input. Use this for
re-running a release for an existing tag without force-pushing.

## 9. Runtime effect

The app, on startup (throttled to once per 12h), fetches the latest GitHub
Release. If the release includes `release-metadata.json` and a matching
`.sha256`, the user can update with full verification.

If SHA is missing (legacy releases), the release info is displayed but the
**install button is disabled** with the message:

> "Phiên bản này thiếu thông tin xác minh."

## 10. Signing certificate change

Android update-in-place requires both:

- the same application ID: `com.zinnodntu.birthdayreminderapp`; and
- the same signing certificate as the installed APK.

If the signing certificate ever needs to change:

1. Ship the new release as a separate applicationId first, OR
2. Provide a side-loaded migration build, OR
3. Document a manual uninstall-and-reinstall step.

The self-update-in-place flow will **not** work across a certificate change.
The audited `v1.0.0` signer matches the current local debug certificate.
Selecting a new permanent production certificate therefore requires a
one-time migration for existing `v1.0.0` installations. No physical-device
test was performed during this signing audit.
