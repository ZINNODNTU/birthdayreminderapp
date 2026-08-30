/// Represents the current state of the update check/download/install process.
enum UpdateStatus {
  /// No operation in progress, no known update.
  idle,

  /// Checking for updates (network request).
  checking,

  /// Up to date; no newer release available.
  upToDate,

  /// A newer release is available.
  updateAvailable,

  /// Update uses a different signing certificate and requires reinstall.
  reinstallRequired,

  /// Downloading the APK.
  downloading,

  /// Download completed, verifying checksum.
  verifying,

  /// Verification passed, ready to install.
  readyToInstall,

  /// Android requires unknown-source permission for this app.
  installPermissionRequired,

  /// Installation in progress (intent launched).
  installing,

  /// An error occurred.
  error,
}
