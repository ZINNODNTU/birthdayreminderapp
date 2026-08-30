import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/ai_provider.dart';

/// Minimal Anthropic Messages API client.
class AnthropicClient {
  AnthropicClient({http.Client? client}) : _client = client ?? http.Client();

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
    final stopwatch = Stopwatch()..start();
    try {
      final response = await _client
          .post(
            Uri.parse('https://api.anthropic.com/v1/messages'),
            headers: {
              'x-api-key': apiKey,
              'anthropic-version': '2023-06-01',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': model,
              'max_tokens': 5,
              'messages': [
                {'role': 'user', 'content': 'Trả lời đúng một từ: OK'},
              ],
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
      if (response.statusCode == 401) {
        return AiConnectionResult.failure(
          code: 'unauthorized',
          message: 'API Key không hợp lệ.',
        );
      }
      if (response.statusCode == 404) {
        return AiConnectionResult.failure(
          code: 'model_not_found',
          message: 'Model không tồn tại.',
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

  Future<AiConnectionResult> chat({
    required String apiKey,
    required String model,
    required String prompt,
    AiRequestOptions? options,
  }) async {
    if (apiKey.isEmpty) {
      return AiConnectionResult.failure(code: 'missing_api_key');
    }
    final effectiveTimeout = options?.timeout ?? _defaultChatTimeout;
    final stopwatch = Stopwatch()..start();
    try {
      final response = await _client
          .post(
            Uri.parse('https://api.anthropic.com/v1/messages'),
            headers: {
              'x-api-key': apiKey,
              'anthropic-version': '2023-06-01',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': model,
              'max_tokens': 1024,
              'messages': [
                {'role': 'user', 'content': prompt},
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
      final content = (decoded as Map<String, dynamic>)['content'];
      if (content is List && content.isNotEmpty) {
        final first = content.first;
        if (first is Map<String, dynamic>) {
          final text = first['text'];
          if (text is String) return text.trim();
        }
      }
    } catch (_) {}
    return '';
  }
}
