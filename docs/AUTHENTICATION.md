# Authentication

## Summary

The app uses **Google Sign-In** as the only authentication method. Email,
password, registration, and password reset flows are intentionally absent.

Local-only usage is preserved via `SessionController.enableLocalMode()`.

## Flow

1. User opens the app and lands on `AuthScreen`.
2. Two buttons:
   * `Tiếp tục với Google` — invokes `AuthRepository.signInWithGoogle()`.
   * `Tiếp tục trên thiết bị` — invokes `SessionController.enableLocalMode()`.
3. `FirebaseAuthRepository.signInWithGoogle()` drives the native
   Google account chooser via `google_sign_in ^7.2.x`,
   exchanges the ID token with Firebase, and asserts
   `user.providerData.contains('google.com')` before returning.
4. `SessionController` listens to `authStateChanges` and calls
   `UserProfileRepository.ensureProfile(user)` on every fresh sign-in.
5. `AuthGate` switches to `Homepage` once `AppSessionMode` becomes
   `authenticated` or `local`.

## Failure handling

`AuthFailure.fromAny(error)` maps platform errors into typed subclasses:

| Code                                | Failure               | UX message                       |
| ----------------------------------- | --------------------- | -------------------------------- |
| `network-request-failed`            | `AuthFailureNetwork`  | "Không có kết nối mạng"          |
| `user-disabled`                     | `AuthFailureUserDisabled` | "Tài khoản đã bị vô hiệu hóa" |
| `operation-not-allowed`             | `AuthFailureOperationNotAllowed` | "Đăng nhập bằng Google chưa được bật..." |
| `too-many-requests`                 | `AuthFailureTooManyRequests` | "Quá nhiều yêu cầu, vui lòng thử lại sau" |
| `canceled` / `sign_in_canceled`     | `AuthFailureCancelled` | Silent (no snackbar)           |
| anything else                       | `AuthFailureUnknown`   | "Đã xảy ra lỗi, vui lòng thử lại" |

`AuthFailureCancelled` is intentionally non-error: the user simply
dismissed the chooser.

## Profile document

After every successful sign-in, `UserProfileRepository.ensureProfile()`
upserts `/users/{uid}` with the canonical schema described in
[`FIRESTORE_SCHEMA.md`](FIRESTORE_SCHEMA.md).

## Local Mode

`SessionRepository` persists `localModeEnabled` in `SharedPreferences`.
When `enableLocalMode()` is called, `SessionController.mode` becomes
`AppSessionMode.local` and `AuthGate` shows `Homepage` even without a
Firebase user. Cloud features (sync, profile) stay disabled.

## Configuration

* Android: `google-services.json` already configured for project
  `birthdayreminderapp-89e7d`. Google Sign-In uses the Firebase
  Android client ID automatically.
* iOS: `GoogleService-Info.plist` is the auth source for the iOS
  Google Sign-In client. The `REVERSED_CLIENT_ID` URL scheme is
  registered in `Info.plist`.

## What's deliberately NOT here

* Email/password registration, login, and reset.
* Phone auth, anonymous auth, MFA, custom tokens.
* Account deletion flow (Phase 7).
* Release signing config (Phase 7).
* Self-update flow (Phase 7).
