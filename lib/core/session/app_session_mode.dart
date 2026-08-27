/// Three mutually-exclusive high-level session states the app can be in.
///
/// * [unauthenticated] — no Firebase user and user has not chosen local mode.
///   Show the [AuthScreen].
/// * [local] — user opted in to device-only mode via "Tiếp tục trên thiết bị".
///   Show the [Homepage] with cloud features gated.
/// * [authenticated] — a Firebase user is signed in. Show the [Homepage]
///   with cloud features enabled.
enum AppSessionMode { unauthenticated, local, authenticated }
