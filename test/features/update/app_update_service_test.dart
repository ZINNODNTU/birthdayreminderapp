import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:birthdayreminderapp/features/update/models/app_release.dart';
import 'package:birthdayreminderapp/features/update/models/update_status.dart';
import 'package:birthdayreminderapp/features/update/repositories/github_release_repository.dart';
import 'package:birthdayreminderapp/features/update/services/app_update_service.dart';

class _StubRepo extends GithubReleaseRepository {
  _StubRepo(this.releaseResponse, {this.sha, this.fail = false})
    : super(client: http.Client());

  final Map<String, dynamic>? releaseResponse;
  final String? sha;
  final bool fail;

  @override
  Future<AppRelease?> fetchLatestRelease() async {
    if (fail) throw Exception('network down');
    if (releaseResponse == null) return null;
    // Reuse parser via JSON.
    // (Same logic as production: skip drafts/prereleases.)
    final j = releaseResponse!;
    if (j['draft'] == true || j['prerelease'] == true) return null;
    final tag = j['tag_name'] as String?;
    if (tag == null) return null;
    final ver = tag.startsWith('v') ? tag.substring(1) : tag;
    final assets = j['assets'] as List?;
    if (assets == null || assets.isEmpty) return null;
    Map<String, dynamic>? apk;
    for (final a in assets) {
      final n = (a as Map)['name'] as String?;
      if (n != null && n.endsWith('.apk')) apk = a.cast<String, dynamic>();
    }
    if (apk == null) return null;
    return AppRelease(
      version: ver,
      buildNumber: 1,
      tagName: tag,
      releaseName: j['name'] as String?,
      publishedAt: DateTime.tryParse(j['published_at'] ?? '') ?? DateTime.now(),
      releaseNotes: j['body'] as String? ?? '',
      apkName: apk['name'] as String,
      apkDownloadUrl: apk['browser_download_url'] as String,
      apkSize: apk['size'] as int? ?? 0,
      sha256: '',
      isMandatory: j['forceUpdate'] as bool? ?? false,
    );
  }

  @override
  Future<String?> fetchSha256(AppRelease release) async => sha;
}

Future<AppUpdateService> _setup({
  required GithubReleaseRepository repo,
  required SharedPreferences prefs,
  String? installedVersion,
}) async {
  return AppUpdateService(
    repository: repo,
    prefs: prefs,
    installedVersionLoader: installedVersion == null
        ? null
        : () async => PackageInfo(
            appName: 'Birthday Reminder',
            packageName: 'x',
            version: installedVersion,
            buildNumber: '1',
          ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppUpdateService.checkForUpdates', () {
    test('upToDate when no release exists', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = await _setup(repo: _StubRepo(null), prefs: prefs);
      await service.checkForUpdates(manual: true);
      expect(service.status, UpdateStatus.upToDate);
      expect(service.latestRelease, isNull);
    });

    test(
      'error when latest release has no SHA and fetchSha256 fails',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final service = await _setup(
          repo: _StubRepo({
            'tag_name': 'v1.0.1',
            'name': 'r',
            'body': '',
            'draft': false,
            'prerelease': false,
            'published_at': '2026-01-01T00:00:00Z',
            'assets': [
              {
                'name': 'BirthdayReminder-v1.0.1.apk',
                'browser_download_url': 'https://github.com/owner/repo/releases/download/v1.0.1/app.apk',
                'size': 1234,
              },
            ],
          }, sha: null),
          prefs: prefs,
        );
        await service.checkForUpdates(manual: true);
        expect(service.status, UpdateStatus.updateAvailable);
        expect(service.latestRelease, isNotNull);
        expect(service.errorMessage, contains('thiếu thông tin xác minh'));
      },
    );

    test('error when network fails', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = await _setup(
        repo: _StubRepo(null, fail: true),
        prefs: prefs,
      );
      await service.checkForUpdates(manual: true);
      expect(service.status, UpdateStatus.error);
    });

    test('upToDate when latest release version equals installed', () async {
      final prefs = await SharedPreferences.getInstance();
      // Mock PackageInfo channel.
      const channel = MethodChannel('dev.fluttercommunity.plus/package_info');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getAll') {
              return {
                'version': '2.1.0',
                'buildNumber': '9',
                'packageName': 'x',
              };
            }
            return null;
          });
      final service = await _setup(
        repo: _StubRepo({
          'tag_name': 'v2.1.0',
          'name': 'r',
          'body': '',
          'draft': false,
          'prerelease': false,
          'published_at': '2026-01-01T00:00:00Z',
          'assets': [
            {
              'name': 'BirthdayReminder-v2.1.0.apk',
              'browser_download_url': 'https://github.com/owner/repo/releases/download/v2.1.0/app.apk',
              'size': 1234,
            },
          ],
        }, sha: 'A' * 64),
        prefs: prefs,
        installedVersion: '2.1.0',
      );
      await service.checkForUpdates(manual: true);
      expect(service.status, UpdateStatus.upToDate);
    });

    test('updateAvailable when latest release version > installed', () async {
      final prefs = await SharedPreferences.getInstance();
      const channel = MethodChannel('dev.fluttercommunity.plus/package_info');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getAll') {
              return {
                'version': '2.0.6',
                'buildNumber': '8',
                'packageName': 'x',
              };
            }
            return null;
          });
      final service = await _setup(
        repo: _StubRepo({
          'tag_name': 'v2.1.0',
          'name': 'r',
          'body': '',
          'draft': false,
          'prerelease': false,
          'published_at': '2026-01-01T00:00:00Z',
          'assets': [
            {
              'name': 'BirthdayReminder-v2.1.0.apk',
              'browser_download_url': 'https://github.com/owner/repo/releases/download/v2.1.0/app.apk',
              'size': 1234,
            },
          ],
        }, sha: 'A' * 64),
        prefs: prefs,
        installedVersion: '2.0.6',
      );
      await service.checkForUpdates(manual: true);
      expect(service.status, UpdateStatus.updateAvailable);
      expect(service.latestRelease, isNotNull);
    });

    test('ignored version forces upToDate', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('update_ignored_version', '1.0.1');
      const channel = MethodChannel('dev.fluttercommunity.plus/package_info');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getAll') {
              return {
                'version': '1.0.0',
                'buildNumber': '1',
                'packageName': 'x',
              };
            }
            return null;
          });
      final service = await _setup(
        repo: _StubRepo({
          'tag_name': 'v1.0.1',
          'name': 'r',
          'body': '',
          'draft': false,
          'prerelease': false,
          'published_at': '2026-01-01T00:00:00Z',
          'assets': [
            {
              'name': 'BirthdayReminder-v1.0.1.apk',
              'browser_download_url': 'https://github.com/owner/repo/releases/download/v1.0.1/app.apk',
              'size': 1234,
            },
          ],
        }, sha: 'A' * 64),
        prefs: prefs,
      );
      await service.checkForUpdates(manual: true);
      expect(service.status, UpdateStatus.upToDate);
    });
  });

  group('AppUpdateService throttling', () {
    test('non-manual check skips within 12h', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        'update_last_check',
        DateTime.now().millisecondsSinceEpoch - 60 * 1000,
      );
      var calls = 0;
      final repo = _ThrottleRepo(() => calls++);
      final service = AppUpdateService(repository: repo, prefs: prefs);
      await service.checkForUpdates();
      expect(calls, 0);
    });

    test('manual check bypasses throttle', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        'update_last_check',
        DateTime.now().millisecondsSinceEpoch - 60 * 1000,
      );
      var calls = 0;
      final repo = _ThrottleRepo(() => calls++);
      final service = AppUpdateService(repository: repo, prefs: prefs);
      await service.checkForUpdates(manual: true);
      expect(calls, 1);
    });
  });

  group('AppUpdateService.ignoreVersion', () {
    test('stores ignored version and clears release', () async {
      final prefs = await SharedPreferences.getInstance();
      const channel = MethodChannel('dev.fluttercommunity.plus/package_info');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getAll') {
              return {
                'version': '1.0.0',
                'buildNumber': '1',
                'packageName': 'x',
              };
            }
            return null;
          });
      final service = await _setup(
        repo: _StubRepo({
          'tag_name': 'v1.0.1',
          'name': 'r',
          'body': '',
          'draft': false,
          'prerelease': false,
          'published_at': '2026-01-01T00:00:00Z',
          'assets': [
            {
              'name': 'BirthdayReminder-v1.0.1.apk',
              'browser_download_url': 'https://github.com/owner/repo/releases/download/v1.0.1/app.apk',
              'size': 1234,
            },
          ],
        }, sha: 'A' * 64),
        prefs: prefs,
        installedVersion: '1.0.0',
      );
      await service.checkForUpdates(manual: true);
      expect(service.latestRelease, isNotNull);
      service.ignoreVersion();
      expect(service.status, UpdateStatus.upToDate);
      expect(service.latestRelease, isNull);
      expect(prefs.getString('update_ignored_version'), '1.0.1');
    });

    test('forceUpdate cannot be ignored', () async {
      final prefs = await SharedPreferences.getInstance();
      const channel = MethodChannel('dev.fluttercommunity.plus/package_info');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (_) async => {
              'version': '2.0.6',
              'buildNumber': '8',
              'packageName': 'x',
            },
          );
      final service = await _setup(
        repo: _StubRepo({
          'tag_name': 'v2.1.0',
          'forceUpdate': true,
          'draft': false,
          'prerelease': false,
          'assets': [
            {
              'name': 'BirthdayReminder-v2.1.0.apk',
              'browser_download_url': 'https://example.com/app.apk',
              'size': 1234,
            },
          ],
        }, sha: 'A' * 64),
        prefs: prefs,
        installedVersion: '2.0.6',
      );
      await service.checkForUpdates(manual: true);
      service.ignoreVersion();
      expect(service.status, UpdateStatus.updateAvailable);
      expect(service.latestRelease?.isMandatory, isTrue);
      expect(prefs.getString('update_ignored_version'), isNull);
    });
  });
}

class _ThrottleRepo extends GithubReleaseRepository {
  _ThrottleRepo(this.onCall) : super(client: http.Client());
  final void Function() onCall;

  @override
  Future<AppRelease?> fetchLatestRelease() async {
    onCall();
    return null;
  }
}
