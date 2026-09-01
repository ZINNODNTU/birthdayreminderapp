import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

class ApkDownloadException implements Exception {
  const ApkDownloadException(this.message, [this.cause]);
  final String message;
  final Object? cause;
  @override
  String toString() => message;
}

class ApkDownloadResult {
  const ApkDownloadResult({required this.file, required this.downloadedBytes});
  final File file;
  final int downloadedBytes;
}

typedef DownloadProgress = void Function(int downloadedBytes, int? totalBytes);
typedef DownloadUrlProvider = Future<Uri> Function(int attempt);
typedef HttpClientFactory = http.Client Function();

class ApkDownloadService {
  ApkDownloadService({
    HttpClientFactory? clientFactory,
    Future<void> Function(Duration)? delay,
  }) : _clientFactory = clientFactory ?? http.Client.new,
       _delay = delay ?? Future<void>.delayed;

  final HttpClientFactory _clientFactory;
  final Future<void> Function(Duration) _delay;

  Future<ApkDownloadResult> download({
    required DownloadUrlProvider urlProvider,
    required Directory directory,
    required String fileName,
    required String userAgent,
    required int expectedSize,
    DownloadProgress? onProgress,
    int maxAttempts = 3,
  }) async {
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final finalFile = File('${directory.path}/$safeName');
    final partFile = File('${finalFile.path}.part');
    await directory.create(recursive: true);
    await _deleteIfExists(partFile);
    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      http.Client? client;
      IOSink? sink;
      try {
        await _deleteIfExists(partFile);
        final url = await urlProvider(attempt);
        client = _clientFactory();
        final request = http.Request('GET', url)
          ..followRedirects = true
          ..maxRedirects = 10
          ..headers.addAll({
            'User-Agent': userAgent,
            'Accept': 'application/octet-stream',
          });
        final response = await client
            .send(request)
            .timeout(const Duration(seconds: 30));
        if (response.statusCode != HttpStatus.ok) {
          throw ApkDownloadException('HTTP ${response.statusCode}');
        }
        final total =
            response.contentLength ?? (expectedSize > 0 ? expectedSize : null);
        var downloaded = 0;
        sink = partFile.openWrite();
        await for (final chunk in response.stream) {
          sink.add(chunk);
          downloaded += chunk.length;
          onProgress?.call(downloaded, total);
        }
        await sink.flush();
        await sink.close();
        sink = null;
        final actualSize = await partFile.length();
        if (actualSize <= 0 ||
            (expectedSize > 0 && actualSize != expectedSize)) {
          throw const ApkDownloadException('Downloaded file size mismatch');
        }
        await _deleteIfExists(finalFile);
        final completed = await partFile.rename(finalFile.path);
        return ApkDownloadResult(file: completed, downloadedBytes: actualSize);
      } catch (error) {
        lastError = error;
        await sink?.close();
        await _deleteIfExists(partFile);
        if (attempt < maxAttempts) {
          await _delay(Duration(seconds: 1 << (attempt - 1)));
        }
      } finally {
        client?.close();
      }
    }
    throw ApkDownloadException(
      'Không thể tải APK sau $maxAttempts lần thử.',
      lastError,
    );
  }

  Future<void> _deleteIfExists(File file) async {
    if (await file.exists()) await file.delete();
  }
}
