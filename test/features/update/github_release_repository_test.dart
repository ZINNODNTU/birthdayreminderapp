import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:birthdayreminderapp/features/update/models/app_release.dart';
import 'package:birthdayreminderapp/features/update/repositories/github_release_repository.dart';

Map<String, dynamic> _structuredRelease({
  String tag = 'v1.0.1',
  String version = '1.0.1',
  int apkSize = 12345678,
  bool draft = false,
  bool prerelease = false,
  String apkName = 'BirthdayReminder-v1.0.1.apk',
}) {
  return {
    'tag_name': tag,
    'name': 'Birthday Reminder $version',
    'body': 'Release notes for $version',
    'draft': draft,
    'prerelease': prerelease,
    'published_at': '2026-01-01T00:00:00Z',
    'html_url': 'https://github.com/owner/repo/releases/tag/$tag',
    'assets': [
      {
        'name': apkName,
        'browser_download_url':
            'https://github.com/owner/repo/releases/download/$tag/$apkName',
        'size': apkSize,
      },
    ],
  };
}

AppRelease _fakeRelease({String apkUrl = 'https://example.com/app.apk'}) {
  return AppRelease(
    version: '1.0.1',
    buildNumber: 1,
    tagName: 'v1.0.1',
    releaseName: null,
    publishedAt: DateTime(2026, 1, 1),
    releaseNotes: '',
    apkName: 'app.apk',
    apkDownloadUrl: apkUrl,
    apkSize: 100,
    sha256: '',
  );
}

void main() {
  group('GithubReleaseRepository.fetchLatestRelease', () {
    test('parses a structured release', () async {
      final client = MockClient((req) async {
        expect(req.url.path, endsWith('/releases/latest'));
        return http.Response(jsonEncode(_structuredRelease()), 200);
      });
      final repo = GithubReleaseRepository(client: client);
      final release = await repo.fetchLatestRelease();
      expect(release, isNotNull);
      expect(release!.version, '1.0.1');
      expect(release.tagName, 'v1.0.1');
      expect(release.apkName, 'BirthdayReminder-v1.0.1.apk');
      expect(release.apkSize, 12345678);
      expect(release.sha256, '');
    });

    test('parses a legacy release (no SHA, no metadata)', () async {
      final client = MockClient((req) async {
        return http.Response(jsonEncode(_structuredRelease()), 200);
      });
      final repo = GithubReleaseRepository(client: client);
      final release = await repo.fetchLatestRelease();
      expect(release, isNotNull);
      expect(release!.sha256, '');
      expect(release.releaseNotes, contains('Release notes'));
    });

    test('ignores draft releases', () async {
      final client = MockClient((req) async {
        return http.Response(jsonEncode(_structuredRelease(draft: true)), 200);
      });
      final repo = GithubReleaseRepository(client: client);
      expect(await repo.fetchLatestRelease(), isNull);
    });

    test('ignores prerelease releases', () async {
      final client = MockClient((req) async {
        return http.Response(
          jsonEncode(_structuredRelease(prerelease: true)),
          200,
        );
      });
      final repo = GithubReleaseRepository(client: client);
      expect(await repo.fetchLatestRelease(), isNull);
    });

    test('returns null when no APK asset', () async {
      final body = _structuredRelease();
      (body['assets'] as List).clear();
      final client = MockClient(
        (req) async => http.Response(jsonEncode(body), 200),
      );
      final repo = GithubReleaseRepository(client: client);
      expect(await repo.fetchLatestRelease(), isNull);
    });

    test('returns null for malformed tag version', () async {
      final body = _structuredRelease(tag: 'not-a-version');
      final client = MockClient(
        (req) async => http.Response(jsonEncode(body), 200),
      );
      final repo = GithubReleaseRepository(client: client);
      expect(await repo.fetchLatestRelease(), isNull);
    });

    test('strips v prefix from tag', () async {
      final client = MockClient((req) async {
        return http.Response(jsonEncode(_structuredRelease()), 200);
      });
      final repo = GithubReleaseRepository(client: client);
      final release = await repo.fetchLatestRelease();
      expect(release!.version, '1.0.1');
    });

    test('accepts tag without v prefix', () async {
      final client = MockClient((req) async {
        return http.Response(
          jsonEncode(_structuredRelease(tag: '2.3.4', version: '2.3.4')),
          200,
        );
      });
      final repo = GithubReleaseRepository(client: client);
      final release = await repo.fetchLatestRelease();
      expect(release, isNotNull);
      expect(release!.version, '2.3.4');
    });

    test('throws on network failure', () async {
      final client = MockClient((req) async => http.Response('Not Found', 404));
      final repo = GithubReleaseRepository(client: client);
      expect(repo.fetchLatestRelease(), throwsException);
    });

    test('throws on JSON parse error', () async {
      final client = MockClient((req) async => http.Response('not-json', 200));
      final repo = GithubReleaseRepository(client: client);
      expect(repo.fetchLatestRelease(), throwsException);
    });
  });

  group('GithubReleaseRepository.fetchRecentReleases', () {
    test('parses multiple releases and skips invalid', () async {
      final body = [
        _structuredRelease(tag: 'v1.0.1'),
        _structuredRelease(tag: 'v1.0.0'),
        _structuredRelease(draft: true),
        _structuredRelease(prerelease: true),
        {'tag_name': 'broken'},
      ];
      final client = MockClient(
        (req) async => http.Response(jsonEncode(body), 200),
      );
      final repo = GithubReleaseRepository(client: client);
      final releases = await repo.fetchRecentReleases(limit: 10);
      expect(releases.length, 2);
      expect(releases.first.version, '1.0.1');
      expect(releases.last.version, '1.0.0');
    });

    test('throws on network failure', () async {
      final client = MockClient((req) async => http.Response('error', 500));
      final repo = GithubReleaseRepository(client: client);
      expect(repo.fetchRecentReleases(), throwsException);
    });
  });

  group('GithubReleaseRepository.fetchSha256', () {
    test('returns trimmed SHA from .sha256 body', () async {
      final client = MockClient((req) async {
        expect(req.url.path, endsWith('.sha256'));
        return http.Response(
          'ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789  BirthdayReminder-v1.0.1.apk\n',
          200,
        );
      });
      final repo = GithubReleaseRepository(client: client);
      final sha = await repo.fetchSha256(
        _fakeRelease(apkUrl: 'https://example.com/app.apk'),
      );
      expect(
        sha,
        'ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789',
      );
    });

    test('returns null on 404', () async {
      final client = MockClient((req) async => http.Response('Not Found', 404));
      final repo = GithubReleaseRepository(client: client);
      expect(await repo.fetchSha256(_fakeRelease()), isNull);
    });

    test('returns null on empty body', () async {
      final client = MockClient((req) async => http.Response('', 200));
      final repo = GithubReleaseRepository(client: client);
      final sha = await repo.fetchSha256(_fakeRelease());
      expect(sha == null || sha.isEmpty, isTrue);
    });
  });
}
