import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/logging/app_logger.dart';
import '../models/app_release.dart';
import '../models/update_status.dart';
import '../repositories/github_release_repository.dart';
import '../utils/semantic_version.dart';
import '../utils/sha256_utils.dart';
import '../platform/apk_installer.dart';
import 'apk_download_service.dart';

/// Service that handles update checks, downloads, and installation.
class AppUpdateService extends ChangeNotifier {
  AppUpdateService({
    required GithubReleaseRepository repository,
    required SharedPreferences prefs,
    ApkDownloadService? downloadService,
    Future<PackageInfo?> Function()? installedVersionLoader,
  }) : _repository = repository,
       _prefs = prefs,
       _downloadService = downloadService ?? ApkDownloadService(),
       _installedVersionLoader =
           installedVersionLoader ?? PackageInfo.fromPlatform {
    _loadCachedState();
  }

  final GithubReleaseRepository _repository;
  final SharedPreferences _prefs;
  final ApkDownloadService _downloadService;
  final Future<PackageInfo?> Function() _installedVersionLoader;

  // State
  UpdateStatus _status = UpdateStatus.idle;
  AppRelease? _latestRelease;
  String? _errorMessage;
  double _downloadProgress = 0.0;
  int _downloadedBytes = 0;
  int? _totalBytes;
  File? _downloadedApk;

  // Cached preferences keys
  static const String _lastCheckKey = 'update_last_check';
  static const String _ignoredVersionKey = 'update_ignored_version';

  // Getters
  UpdateStatus get status => _status;
  AppRelease? get latestRelease => _latestRelease;
  String? get errorMessage => _errorMessage;
  double get downloadProgress => _downloadProgress;
  int get downloadedBytes => _downloadedBytes;
  int? get totalBytes => _totalBytes;
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
          changes: release.changes,
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

  /// Stream the latest APK to an atomic cache file with transient retries.
  Future<void> downloadUpdate() async {
    if ((_status != UpdateStatus.updateAvailable &&
            _status != UpdateStatus.error) ||
        _latestRelease == null) {
      return;
    }

    _setStatus(UpdateStatus.downloading);
    _downloadProgress = 0;
    _downloadedBytes = 0;
    _totalBytes = _latestRelease!.apkSize > 0 ? _latestRelease!.apkSize : null;
    final release = _latestRelease!;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final tempDir = await getApplicationCacheDirectory();
      final updateDir = Directory('${tempDir.path}/updates');
      final result = await _downloadService.download(
        directory: updateDir,
        fileName: release.apkName,
        expectedSize: release.apkSize,
        userAgent: 'BirthdayReminder/${packageInfo.version}',
        urlProvider: (attempt) async {
          if (attempt == 1) return Uri.parse(release.apkDownloadUrl);
          final refreshed = await _repository.fetchLatestRelease();
          if (refreshed == null ||
              refreshed.tagName != release.tagName ||
              refreshed.apkDownloadUrl.isEmpty) {
            throw const ApkDownloadException('APK URL is unavailable');
          }
          return Uri.parse(refreshed.apkDownloadUrl);
        },
        onProgress: (downloaded, total) {
          _downloadedBytes = downloaded;
          _totalBytes = total;
          _downloadProgress =
              total != null && total > 0 ? downloaded / total : 0;
          notifyListeners();
        },
      );
      _downloadedApk = result.file;

      _setStatus(UpdateStatus.verifying);
      final hash = await Sha256Utils.hashFile(result.file);
      if (hash.toUpperCase() != release.sha256.toUpperCase()) {
        await result.file.delete();
        _downloadedApk = null;
        throw const ApkDownloadException('APK checksum mismatch');
      }
      _setStatus(UpdateStatus.readyToInstall);
    } catch (error, stackTrace) {
      AppLogger.error('UpdateDownload', error, stackTrace);
      _errorMessage =
          'Tải bản cập nhật không thành công. Vui lòng kiểm tra kết nối mạng và thử lại.';
      _setStatus(UpdateStatus.error);
      if (_downloadedApk != null && await _downloadedApk!.exists()) {
        await _downloadedApk!.delete();
      }
      _downloadedApk = null;
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
    if (_latestRelease != null && !_latestRelease!.isMandatory) {
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
      return await _installedVersionLoader();
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
