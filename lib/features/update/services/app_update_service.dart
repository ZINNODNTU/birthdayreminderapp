import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/app_release.dart';
import '../models/update_status.dart';
import '../repositories/github_release_repository.dart';
import '../utils/semantic_version.dart';
import '../utils/sha256_utils.dart';
import '../platform/apk_installer.dart';

/// Service that handles update checks, downloads, and installation.
class AppUpdateService extends ChangeNotifier {
  AppUpdateService({
    required GithubReleaseRepository repository,
    required SharedPreferences prefs,
  }) : _repository = repository,
       _prefs = prefs {
    _loadCachedState();
  }

  final GithubReleaseRepository _repository;
  final SharedPreferences _prefs;

  // State
  UpdateStatus _status = UpdateStatus.idle;
  AppRelease? _latestRelease;
  String? _errorMessage;
  double _downloadProgress = 0.0;
  File? _downloadedApk;

  // Cached preferences keys
  static const String _lastCheckKey = 'update_last_check';
  static const String _ignoredVersionKey = 'update_ignored_version';

  // Getters
  UpdateStatus get status => _status;
  AppRelease? get latestRelease => _latestRelease;
  String? get errorMessage => _errorMessage;
  double get downloadProgress => _downloadProgress;
  bool get isDownloading => _status == UpdateStatus.downloading;

  // Auto-check interval (12 hours)
  static const Duration _autoCheckInterval = Duration(hours: 12);

  /// Load cached state (last check time, ignored version)
  void _loadCachedState() {
    // No state to load besides prefs.
  }

  /// Check for updates manually (bypass throttle).
  Future<void> checkForUpdates({bool manual = false}) async {
    if (_status == UpdateStatus.checking) return;

    // Throttle: if not manual and last check was recent, skip.
    if (!manual) {
      final lastCheck = _prefs.getInt(_lastCheckKey);
      if (lastCheck != null) {
        final elapsed = DateTime.now().millisecondsSinceEpoch - lastCheck;
        if (elapsed < _autoCheckInterval.inMilliseconds) {
          // Still up-to-date? We'll keep current state.
          return;
        }
      }
    }

    _setStatus(UpdateStatus.checking);
    _errorMessage = null;

    try {
      final release = await _repository.fetchLatestRelease();
      if (release == null) {
        // No release found (maybe no stable release)
        _setStatus(UpdateStatus.upToDate);
        _latestRelease = null;
        return;
      }

      // Fetch SHA256 if missing. Legacy releases remain displayable but are
      // not downloadable/installable because they cannot be verified.
      if (release.sha256.isEmpty) {
        final sha = await _repository.fetchSha256(release);
        if (sha == null || sha.isEmpty) {
          _latestRelease = release;
          _errorMessage = 'Phiên bản này thiếu thông tin xác minh.';
          _setStatus(UpdateStatus.updateAvailable);
          return;
        }
        // Re-create release with SHA.
        final verifiedRelease = AppRelease(
          version: release.version,
          buildNumber: release.buildNumber,
          tagName: release.tagName,
          releaseName: release.releaseName,
          publishedAt: release.publishedAt,
          releaseNotes: release.releaseNotes,
          apkName: release.apkName,
          apkDownloadUrl: release.apkDownloadUrl,
          apkSize: release.apkSize,
          sha256: sha,
          isMandatory: release.isMandatory,
          minimumSupportedVersion: release.minimumSupportedVersion,
          githubReleaseUrl: release.githubReleaseUrl,
        );
        _latestRelease = verifiedRelease;
      } else {
        _latestRelease = release;
      }

      // Compare with installed version.
      final installed = await _getInstalledVersion();
      if (installed == null) {
        _errorMessage = 'Không thể đọc phiên bản hiện tại.';
        _setStatus(UpdateStatus.error);
        return;
      }

      final installedSem = SemanticVersion.parse(installed.version);
      final releaseSem = SemanticVersion.parse(_latestRelease!.version);
      if (installedSem == null || releaseSem == null) {
        _errorMessage = 'Lỗi định dạng phiên bản.';
        _setStatus(UpdateStatus.error);
        return;
      }

      // Check ignored version: if release version is ignored, treat as up-to-date.
      final ignored = _prefs.getString(_ignoredVersionKey);
      if (ignored == releaseSem.toString()) {
        _setStatus(UpdateStatus.upToDate);
        _latestRelease = null;
        return;
      }

      if (releaseSem > installedSem) {
        _setStatus(
          _latestRelease!.requiresReinstall
              ? UpdateStatus.reinstallRequired
              : UpdateStatus.updateAvailable,
        );
      } else {
        _setStatus(UpdateStatus.upToDate);
        _latestRelease = null;
      }

      // Update last check time.
      _prefs.setInt(_lastCheckKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      _errorMessage = 'Không thể kiểm tra cập nhật: $e';
      _setStatus(UpdateStatus.error);
    }
  }

  /// Download the latest APK.
  Future<void> downloadUpdate() async {
    if (_status != UpdateStatus.updateAvailable) return;
    if (_latestRelease == null) return;

    _setStatus(UpdateStatus.downloading);
    _downloadProgress = 0.0;

    final release = _latestRelease!;
    final url = Uri.parse(release.apkDownloadUrl);
    final client = http.Client();

    try {
      final response = await client.send(http.Request('GET', url));
      if (response.statusCode != 200) {
        throw Exception('Download failed: ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      int received = 0;
      final tempDir = await getApplicationCacheDirectory();
      final updateDir = Directory('${tempDir.path}/updates');
      if (!await updateDir.exists()) await updateDir.create(recursive: true);
      final apkFile = File('${updateDir.path}/${release.apkName}');
      if (await apkFile.exists()) await apkFile.delete();
      final sink = apkFile.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (contentLength > 0) {
          _downloadProgress = received / contentLength;
          notifyListeners();
        }
      }
      await sink.close();

      _downloadedApk = apkFile;

      // Verify advertised size when present.
      final actualSize = await apkFile.length();
      if (release.apkSize > 0 && actualSize != release.apkSize) {
        await apkFile.delete();
        _errorMessage = 'Dung lượng tệp cập nhật không khớp.';
        _setStatus(UpdateStatus.error);
        _downloadedApk = null;
        return;
      }

      // Verify SHA256.
      _setStatus(UpdateStatus.verifying);
      final hash = await Sha256Utils.hashFile(apkFile);
      if (hash.toUpperCase() != release.sha256.toUpperCase()) {
        await apkFile.delete();
        _errorMessage = 'Tệp cập nhật không hợp lệ hoặc đã bị thay đổi.';
        _setStatus(UpdateStatus.error);
        _downloadedApk = null;
        return;
      }

      _setStatus(UpdateStatus.readyToInstall);
    } catch (e) {
      _errorMessage = 'Lỗi tải xuống: $e';
      _setStatus(UpdateStatus.error);
      if (_downloadedApk != null) {
        await _downloadedApk!.delete();
        _downloadedApk = null;
      }
    } finally {
      client.close();
    }
  }

  /// Launch Android package installer for the downloaded APK.
  Future<void> installUpdate() async {
    if (_status != UpdateStatus.readyToInstall) return;
    if (_downloadedApk == null) return;

    if (kDebugMode) {
      _errorMessage =
          'Bản debug không thể tự cài đặt vì chữ ký có thể khác bản ổn định.';
      _setStatus(UpdateStatus.error);
      return;
    }

    final canInstall = await ApkInstaller.canRequestPackageInstalls();
    if (!canInstall) {
      _errorMessage = 'Cần cho phép cài đặt ứng dụng từ nguồn này.';
      _setStatus(UpdateStatus.installPermissionRequired);
      return;
    }

    _setStatus(UpdateStatus.installing);
    try {
      final success = await ApkInstaller.installApk(_downloadedApk!);
      if (!success) {
        _errorMessage = 'Không thể mở trình cài đặt APK.';
        _setStatus(UpdateStatus.error);
      } else {
        Future.delayed(const Duration(seconds: 5), () {
          if (_status == UpdateStatus.installing) {
            _setStatus(UpdateStatus.idle);
          }
        });
      }
    } catch (_) {
      _errorMessage = 'Không thể mở trình cài đặt APK.';
      _setStatus(UpdateStatus.error);
    }
  }

  /// Dismiss the update notification (ignore this version).
  void ignoreVersion() {
    if (_latestRelease != null) {
      _prefs.setString(_ignoredVersionKey, _latestRelease!.version);
      _latestRelease = null;
      _setStatus(UpdateStatus.upToDate);
    }
  }

  /// Set status and notify.
  void _setStatus(UpdateStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  /// Get installed version info.
  Future<PackageInfo?> _getInstalledVersion() async {
    try {
      return await PackageInfo.fromPlatform();
    } catch (_) {
      return null;
    }
  }

  /// Clean up downloaded APK.
  Future<void> cleanup() async {
    if (_downloadedApk != null && await _downloadedApk!.exists()) {
      await _downloadedApk!.delete();
      _downloadedApk = null;
    }
  }

  @override
  void dispose() {
    cleanup();
    super.dispose();
  }
}
