import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_release.dart';
import '../utils/semantic_version.dart';

/// Fetches release information from GitHub public API.
class GithubReleaseRepository {
  GithubReleaseRepository({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  static const int maxRecentReleases = 10;

  static const String _repoUrl =
      'https://api.github.com/repos/ZINNODNTU/birthdayreminderapp';
  static const String _latestEndpoint = '$_repoUrl/releases/latest';
  static const String _releasesEndpoint = '$_repoUrl/releases';

  /// Fetch the latest release (not draft, not prerelease).
  Future<AppRelease?> fetchLatestRelease() async {
    final response = await _client.get(Uri.parse(_latestEndpoint));
    if (response.statusCode != 200) {
      throw Exception('GitHub API error: ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return await _parseRelease(json);
  }

  /// Fetch a limited number of recent releases (5-10).
  Future<List<AppRelease>> fetchRecentReleases({int limit = 10}) async {
    final safeLimit = limit.clamp(1, maxRecentReleases);
    final response = await _client.get(
      Uri.parse('$_releasesEndpoint?per_page=$safeLimit'),
    );
    if (response.statusCode != 200) {
      throw Exception('GitHub API error: ${response.statusCode}');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    final releases = <AppRelease>[];
    for (final item in list) {
      final release = await _parseRelease(item as Map<String, dynamic>);
      if (release != null) releases.add(release);
    }
    return releases.take(safeLimit).toList();
  }

  Future<AppRelease?> _parseRelease(Map<String, dynamic> json) async {
    // Skip drafts and prereleases.
    if (json['draft'] == true || json['prerelease'] == true) return null;

    final tagName = json['tag_name'] as String?;
    if (tagName == null) return null;
    // Remove 'v' prefix if present.
    final versionStr = tagName.startsWith('v') ? tagName.substring(1) : tagName;
    final sem = SemanticVersion.parse(versionStr);
    if (sem == null) return null; // invalid version

    final assets = json['assets'] as List<dynamic>?;
    if (assets == null || assets.isEmpty) return null;

    // Find APK asset.
    Map<String, dynamic>? apkAsset;
    for (final asset in assets) {
      final name = asset['name'] as String?;
      if (name == null) continue;
      if (name.endsWith('.apk')) apkAsset = asset;
    }
    if (apkAsset == null) return null;

    final apkName = apkAsset['name'] as String;
    final apkDownloadUrl = apkAsset['browser_download_url'] as String;
    final apkSize = apkAsset['size'] as int? ?? 0;
    final releaseNotes = json['body'] as String? ?? '';
    final publishedAt =
        DateTime.tryParse(json['published_at'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final releaseName = json['name'] as String?;
    final githubUrl = json['html_url'] as String?;

    // Prefer release-metadata.json when present. Legacy releases have no
    // metadata and remain display-only until a separate SHA is fetched.
    Map<String, dynamic>? metadata;
    for (final asset in assets) {
      if (asset['name'] == 'release-metadata.json') {
        final metadataUrl = asset['browser_download_url'] as String?;
        if (metadataUrl != null) {
          final response = await _client.get(Uri.parse(metadataUrl));
          if (response.statusCode == 200) {
            final decoded = jsonDecode(response.body);
            if (decoded is Map<String, dynamic>) metadata = decoded;
          }
        }
      }
    }

    var buildNumber = sem.build;
    var sha256 = '';
    var mandatory = false;
    var requiresReinstall = false;
    String? migrationMessage;
    String? minimumSupportedVersion;
    if (metadata != null) {
      final metaVersion = metadata['version'] as String?;
      final apkMeta = metadata['apk'];
      if (metadata['schemaVersion'] != 1 ||
          metaVersion != versionStr ||
          apkMeta is! Map<String, dynamic> ||
          apkMeta['name'] != apkName ||
          apkMeta['size'] != apkSize) {
        return null;
      }
      buildNumber = metadata['buildNumber'] as int? ?? 0;
      sha256 = apkMeta['sha256'] as String? ?? '';
      mandatory = metadata['mandatory'] as bool? ?? false;
      requiresReinstall = metadata['requiresReinstall'] as bool? ?? false;
      migrationMessage = metadata['migrationMessage'] as String?;
      minimumSupportedVersion = metadata['minimumSupportedVersion'] as String?;
      if (!RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(sha256)) return null;
    }

    return AppRelease(
      version: versionStr,
      buildNumber: buildNumber,
      tagName: tagName,
      releaseName: releaseName,
      publishedAt: publishedAt,
      releaseNotes: releaseNotes,
      apkName: apkName,
      apkDownloadUrl: apkDownloadUrl,
      apkSize: apkSize,
      sha256: sha256,
      isMandatory: mandatory,
      minimumSupportedVersion: minimumSupportedVersion,
      githubReleaseUrl: githubUrl,
      requiresReinstall: requiresReinstall,
      migrationMessage: migrationMessage,
    );
  }

  /// Fetch the SHA-256 content from the .sha256 asset.
  Future<String?> fetchSha256(AppRelease release) async {
    // Assume the SHA asset URL is the APK URL with .sha256 appended.
    final shaUrl = '${release.apkDownloadUrl}.sha256';
    final response = await _client.get(Uri.parse(shaUrl));
    if (response.statusCode != 200) return null;
    final content = response.body.trim();
    // Usually the SHA is the first token.
    final parts = content.split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts[0] : null;
  }
}
