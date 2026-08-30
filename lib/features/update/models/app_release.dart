/// A release of the app published on GitHub.
class AppRelease {
  const AppRelease({
    required this.version,
    required this.buildNumber,
    required this.tagName,
    this.releaseName,
    required this.publishedAt,
    required this.releaseNotes,
    required this.apkName,
    required this.apkDownloadUrl,
    required this.apkSize,
    required this.sha256,
    this.isMandatory = false,
    this.minimumSupportedVersion,
    this.githubReleaseUrl,
    this.requiresReinstall = false,
    this.migrationMessage,
  });

  /// Semantic version (e.g. "1.0.1").
  final String version;

  /// Android versionCode (build number).
  final int buildNumber;

  /// Git tag (e.g. "v1.0.1").
  final String tagName;

  /// Release title (optional).
  final String? releaseName;

  /// When the release was published.
  final DateTime publishedAt;

  /// Release notes (GitHub release body).
  final String releaseNotes;

  /// APK filename (e.g. "BirthdayReminder-v1.0.1.apk").
  final String apkName;

  /// Direct download URL for the APK.
  final String apkDownloadUrl;

  /// APK size in bytes.
  final int apkSize;

  /// SHA-256 checksum of the APK.
  final String sha256;

  /// If true, the update is mandatory.
  final bool isMandatory;

  /// Minimum version this update supports (optional).
  final String? minimumSupportedVersion;

  /// URL to the GitHub release page.
  final String? githubReleaseUrl;

  /// True when Android cannot update in place because the signer changes.
  final bool requiresReinstall;

  /// Human-readable migration instructions supplied by release metadata.
  final String? migrationMessage;

  @override
  String toString() => 'AppRelease(version=$version, build=$buildNumber)';
}
