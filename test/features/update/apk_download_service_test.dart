import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:birthdayreminderapp/features/update/services/apk_download_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  late Directory temp;
  setUp(
    () async =>
        temp = await Directory.systemTemp.createTemp('apk_download_test'),
  );
  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('streams chunks to atomic final file and reports progress', () async {
    final chunks = Stream<List<int>>.fromIterable([
      [1, 2],
      [3, 4, 5],
    ]);
    final client = _RecordingClient(
      (request) async => http.StreamedResponse(chunks, 200, contentLength: 5),
    );
    final progress = <int>[];
    final result = await ApkDownloadService(
      clientFactory: () => client,
    ).download(
      urlProvider:
          (_) async =>
              Uri.parse('https://github.com/o/r/releases/download/v/app.apk'),
      directory: temp,
      fileName: 'app.apk',
      userAgent: 'BirthdayReminder/2.0.1',
      expectedSize: 5,
      onProgress: (received, _) => progress.add(received),
    );
    expect(await result.file.readAsBytes(), [1, 2, 3, 4, 5]);
    expect(progress, [2, 5]);
    expect(File('${result.file.path}.part').existsSync(), isFalse);
    expect(client.request!.followRedirects, isTrue);
    expect(client.request!.maxRedirects, 10);
  });

  test(
    'deletes partial file, refreshes URL, then retries successfully',
    () async {
      var clients = 0;
      final urls = <Uri>[];
      final service = ApkDownloadService(
        delay: (_) async {},
        clientFactory: () {
          clients++;
          return _RecordingClient((request) async {
            if (clients == 1) {
              return http.StreamedResponse(
                Stream<List<int>>.error(
                  http.ClientException('Connection closed'),
                ),
                200,
                contentLength: 3,
              );
            }
            return http.StreamedResponse(
              Stream.value([7, 8, 9]),
              200,
              contentLength: 3,
            );
          });
        },
      );
      final result = await service.download(
        urlProvider: (attempt) async {
          final url = Uri.parse('https://github.com/fresh-$attempt.apk');
          urls.add(url);
          return url;
        },
        directory: temp,
        fileName: 'app.apk',
        userAgent: 'BirthdayReminder/2.0.1',
        expectedSize: 3,
      );
      expect(await result.file.readAsBytes(), [7, 8, 9]);
      expect(urls.map((u) => u.host), ['github.com', 'github.com']);
      expect(urls.last.path, '/fresh-2.apk');
      expect(File('${result.file.path}.part').existsSync(), isFalse);
    },
  );

  test('fails safely after three transient failures', () async {
    var attempts = 0;
    final service = ApkDownloadService(
      delay: (_) async {},
      clientFactory:
          () => _RecordingClient((request) async {
            attempts++;
            throw http.ClientException('Connection closed');
          }),
    );
    await expectLater(
      service.download(
        urlProvider: (_) async => Uri.parse('https://github.com/app.apk'),
        directory: temp,
        fileName: 'app.apk',
        userAgent: 'BirthdayReminder/2.0.1',
        expectedSize: 3,
      ),
      throwsA(isA<ApkDownloadException>()),
    );
    expect(attempts, 3);
    expect(File('${temp.path}/app.apk.part').existsSync(), isFalse);
  });

  test('rejects content size mismatch and HTTP errors', () async {
    var calls = 0;
    final service = ApkDownloadService(
      delay: (_) async {},
      clientFactory:
          () => _RecordingClient((request) async {
            calls++;
            return calls == 1
                ? http.StreamedResponse(
                  Stream.value([1, 2]),
                  200,
                  contentLength: 2,
                )
                : http.StreamedResponse(Stream.value(Uint8List(0)), 500);
          }),
    );
    await expectLater(
      service.download(
        urlProvider: (_) async => Uri.parse('https://github.com/app.apk'),
        directory: temp,
        fileName: 'app.apk',
        userAgent: 'BirthdayReminder/2.0.1',
        expectedSize: 3,
        maxAttempts: 2,
      ),
      throwsA(isA<ApkDownloadException>()),
    );
    expect(File('${temp.path}/app.apk').existsSync(), isFalse);
  });
}

typedef _Handler =
    Future<http.StreamedResponse> Function(http.BaseRequest request);

class _RecordingClient extends http.BaseClient {
  _RecordingClient(this.handler);

  final _Handler handler;
  http.BaseRequest? request;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    this.request = request;
    return handler(request);
  }
}
