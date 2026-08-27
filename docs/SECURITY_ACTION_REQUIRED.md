# Phase 0 Security Baseline

## External action required

A Gemini/Generative Language API credential was committed in repository history and embedded in the Flutter client.

Required:
1. Revoke the old Gemini credential in Google Cloud Console.
2. Create any replacement only for a trusted backend.
3. Store replacements in Secret Manager.
4. Apply API restrictions, quotas and billing alerts.

The credential value is intentionally omitted.

## Firebase client configuration

`firebase_options.dart` and `google-services.json` are Firebase client configuration, not backend secrets. Bundling them through `.env` would not make them secret.

Before production:
1. Restrict each key to the intended Android package, iOS bundle ID or web origins.
2. Restrict enabled APIs to the minimum set.
3. Review usage logs for abuse; rotate if exposure policy or evidence requires it.
4. Enable App Check after valid clients are configured.
5. Deploy and emulator-test Firestore rules.

## Current repository remediation

- Direct Gemini HTTP access and embedded Gemini credential removed.
- AI fails closed with a friendly maintenance error; birthday features remain available.
- Firestore data moved from global `/birthdays` to `/users/{uid}/birthdays`.
- Firestore rules deny unauthenticated and cross-user access.
- Android permissions reduced; iOS privacy descriptions added.

## Release gate

Do not publish until Gemini revocation and production Firebase rule deployment are confirmed.
