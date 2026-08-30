# Signing Migration

## Background

The public `v1.0.0` APK and the current Android debug keystore use the same certificate. A new permanent certificate cannot update that installation in place. Package: `com.zinnodntu.birthdayreminderapp`.

## Existing signer fingerprints

- DN: `C=US, O=Android, CN=Android Debug`
- SHA-1: `ED:CD:C4:C2:59:0B:81:F5:C0:80:5F:0E:08:77:FB:5E:35:09:6E:D1`
- SHA-256: `BD:24:C3:98:18:B6:F2:D4:06:0C:DC:F7:14:E2:8D:AE:F9:4F:24:5D:28:B1:72:1A:6F:06:77:E7:B7:3B:0D:A6`

The stable workflow rejects this SHA-256. Never upload `%USERPROFILE%\.android\debug.keystore` as a production secret.

## Local Mode risk

Uninstall normally removes private SQLite data. Birthday CSV export exists, but matching CSV/JSON restore does not. CSV omits photos and sync metadata. Contact import is not backup restoration. Local Mode migration is **blocked** until a migration release provides tested full-fidelity export/import.

## Cloud-user considerations

Authenticated sync covers birthday fields, reminders, photos, and cloud tombstones. Local preferences/settings are not proven cloud-backed. Cloud restore is **partial**, not full.

## Migration release recommendation

1. Implement full-fidelity export/import and migration warnings.
2. Publish transitional `v1.0.1` with the legacy signer.
3. Existing `v1.0.0` installations update to that bridge.
4. Users export and verify backups.
5. Start permanent signing at `v2.0.0`.
6. Users perform one documented uninstall/reinstall and restore.
7. Never use the legacy signer again for normal stable releases.

`v2.0.0` better communicates the breaking installation boundary than `v1.1.0`. No version, tag, or release is created now.

## Permanent-key strategy

Store outside the project, e.g. `D:\SECURE_KEYS\birthdayreminder\birthday-reminder-release.jks`.

```powershell
keytool -genkeypair `
  -v `
  -keystore "D:\SECURE_KEYS\birthdayreminder\birthday-reminder-release.jks" `
  -alias birthday-reminder `
  -keyalg RSA -keysize 4096 -sigalg SHA256withRSA -validity 10000
```

Do not hardcode passwords. Keep at least two encrypted backups in separate locations. Record recovery ownership/process, alias, and fingerprints outside the repository.

```powershell
keytool -list -v -keystore "<permanent-keystore>" -alias "<alias>"
```

Local `android/key.properties` template:

```properties
storeFile=<absolute-path-outside-repo>
storePassword=<secret>
keyAlias=<alias>
keyPassword=<secret>
```

## GitHub Actions

```powershell
$bytes = [System.IO.File]::ReadAllBytes("<keystore>")
[Convert]::ToBase64String($bytes) | Set-Clipboard
```

Create manually via **Repository → Settings → Secrets and variables → Actions → New repository secret**:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_RELEASE_CERT_SHA256`

The workflow fails on missing secrets, tag/version mismatch, tests, analysis, signer mismatch, or the legacy debug SHA-256. Release creation is last.

## Firebase

Use **Project settings → Android app → `com.zinnodntu.birthdayreminderapp` → Add fingerprint**. Add permanent SHA-1 and SHA-256. Keep debug fingerprints.

## Signing-transition metadata and UI

Schema v1 currently ignores unknown fields, so future optional fields can remain compatible:

```json
{
  "requiresReinstall": true,
  "migrationMessage": "Phiên bản này sử dụng chữ ký phát hành mới. Hãy sao lưu dữ liệu Local Mode trước khi cài đặt lại."
}
```

Implement parser/model/UI support and tests before use. For `requiresReinstall`: do not invoke normal installation; show **Yêu cầu cài đặt lại**; warn Local Mode users; link truthful instructions. Do not show **Sao lưu dữ liệu** until full-fidelity backup exists. Do not promise settings or full cloud restoration.

## Future release signing policy

One permanent certificate for all post-migration releases. Never generate a key per release. Never use debug signing for stable production. Verify APK certificate before publication. Back up independently of workstation and GitHub.

## Full-fidelity Local Mode backup readiness

A dedicated schema-v1 ZIP backup/restore implementation now exists; CSV remains reporting-only. It preserves all Birthday fields, tombstones, timestamps, reminder configuration, photo bytes/checksums, and an explicit portable-settings allowlist. Authentication and secrets remain excluded. Signing-migration restore normalizes cloud ownership and sync state to Local Mode safety.

The future sequence remains:

1. v1.0.1, legacy debug signer: create and retain full backup.
2. Uninstall/reinstall boundary.
3. v2.0.0, permanent signer: select, preview, and restore backup.

No migration release or permanent key is created by this implementation. See [BACKUP_RESTORE.md](BACKUP_RESTORE.md).
