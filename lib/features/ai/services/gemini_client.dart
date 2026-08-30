import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/ai_provider.dart';

/// Minimal Google Gemini client (generateContent REST).
class GeminiClient {
  GeminiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration _defaultChatTimeout = Duration(seconds: 60);

  Future<AiConnectionResult> testConnection({
    required String apiKey,
    required String model,
  }) async {
    if (apiKey.isEmpty) {
      return AiConnectionResult.failure(code: 'missing_api_key');
    }
    if (model.isEmpty) {
      return AiConnectionResult.failure(code: 'missing_model');
    }
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
    );
    final stopwatch = Stopwatch()..start();
    try {
      final response = await _client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': 'Trả lời đúng một từ: OK'},
                  ],
                },
              ],
              'generationConfig': {'temperature': 0, 'maxOutputTokens': 5},
            }),
          )
          .timeout(AiTimeouts.connectionTest);
      stopwatch.stop();
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final reply = _extractContent(decoded);
        return AiConnectionResult.success(
          latencyMs: stopwatch.elapsedMilliseconds,
          reply: reply,
        );
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        return AiConnectionResult.failure(
          code: 'unauthorized',
          message: 'API Key không h�p lệ.',
        );
      }
      if (response.statusCode == 404) {
        return AiConnectionResult.failure(
          code: 'model_not_found',
          message: 'Model không tồn tại.',
        );
      }
      if (response.statusCode == 429) {
        return AiConnectionResult.failure(
          code: 'http_429',
          message: 'Đã vượt giới hạn yêu cầu/quota.',
        );
      }
      return AiConnectionResult.failure(
        code: 'http_${response.statusCode}',
        message: 'HTTP ${response.statusCode}',
      );
    } on TimeoutException {
      return AiConnectionResult.failure(code: 'timeout');
    } catch (e) {
      return AiConnectionResult.failure(code: 'network', message: e.toString());
    }
  }

  Future<List<String>> listModels({
    required String apiKey,
    String? baseUrl,
  }) async {
    if (apiKey.isEmpty) return const [];
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models',
    );
    try {
      final response = await _client
          .get(url, headers: {'x-goog-api-key': apiKey})
          .timeout(AiTimeouts.connectionTest);
      if (response.statusCode != 200) return const [];
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['models'] is List) {
        return (decoded['models'] as List)
            .whereType<Map>()
            .map((m) => (m['name'] ?? '').toString())
            .where((id) => id.isNotEmpty)
            .toList(growable: false);
      }
    } catch (_) {
      // ignore; manual entry remains available
    }
    return const [];
  }

  Future<AiConnectionResult> chat({
    required String apiKey,
    required String model,
    required String prompt,
    AiRequestOptions? options,
  }) async {
    if (apiKey.isEmpty) {
      return AiConnectionResult.failure(code: 'missing_api_key');
    }
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '$model:generateContent',
    );
    final effectiveTimeout = options?.timeout ?? _defaultChatTimeout;
    final stopwatch = Stopwatch()..start();
    try {
      final response = await _client
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': apiKey,
            },
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt},
                  ],
                },
              ],
            }),
          )
          .timeout(effectiveTimeout);
      stopwatch.stop();
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return AiConnectionResult.success(
          latencyMs: stopwatch.elapsedMilliseconds,
          reply: _extractContent(decoded),
        );
      }
      return AiConnectionResult.failure(
        code: 'http_${response.statusCode}',
        message: 'HTTP ${response.statusCode}',
      );
    } on TimeoutException {
      return AiConnectionResult.failure(code: 'timeout');
    } catch (e) {
      return AiConnectionResult.failure(code: 'network', message: e.toString());
    }
  }

  String _extractContent(dynamic decoded) {
    try {
      final candidates = (decoded as Map<String, dynamic>)['candidates'];
      if (candidates is List && candidates.isNotEmpty) {
        final first = candidates.first;
        if (first is Map<String, dynamic>) {
          final content = first['content'];
          if (content is Map<String, dynamic>) {
            final parts = content['parts'];
            if (parts is List && parts.isNotEmpty) {
              final text = parts.first['text'];
              if (text is String) return text.trim();
            }
          }
        }
      }
    } catch (_) {}
    return '';
  }
}
