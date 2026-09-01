import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/ai_provider.dart';

/// Minimal OpenAI-compatible client. Covers OpenAI, OpenRouter, Groq,
/// Together and self-hosted gateways that expose `/v1/chat/completions`.
class OpenAiCompatibleClient {
  OpenAiCompatibleClient({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  /// Per-request fallback used when the caller did not pass a
  /// [AiRequestOptions] (i.e. legacy callers / tests).
  static const Duration _defaultChatTimeout = Duration(seconds: 60);

  String _defaultBaseUrl() => 'https://api.openai.com/v1';

  Future<AiConnectionResult> testConnection({
    required String apiKey,
    required String model,
    String? baseUrl,
  }) async {
    if (apiKey.isEmpty) {
      return AiConnectionResult.failure(
        code: 'missing_api_key',
        message: 'API key is required.',
      );
    }
    if (model.isEmpty) {
      return AiConnectionResult.failure(
        code: 'missing_model',
        message: 'Model id is required.',
      );
    }
    final base = (baseUrl == null || baseUrl.isEmpty)
        ? _defaultBaseUrl()
        : baseUrl;
    final url = Uri.parse('$base/chat/completions');
    final stopwatch = Stopwatch()..start();
    try {
      final response = await _client
          .post(
            url,
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': model,
              'messages': [
                {'role': 'user', 'content': 'Trả lời đúng một từ: OK'},
              ],
              'temperature': 0,
              'max_tokens': 5,
            }),
          )
          .timeout(AiTimeouts.connectionTest);
      stopwatch.stop();
      final latency = stopwatch.elapsedMilliseconds;
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final reply = _extractContent(decoded);
        return AiConnectionResult.success(latencyMs: latency, reply: reply);
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        return AiConnectionResult.failure(
          code: 'unauthorized',
          message:
              _safeErrorMessage(response.body) ??
              'API key không hợp lệ hoặc không có quyền truy cập.',
        );
      }
      if (response.statusCode == 404) {
        return AiConnectionResult.failure(
          code: 'model_not_found',
          message:
              _safeErrorMessage(response.body) ??
              'Không tìm thấy model hoặc endpoint.',
        );
      }
      if (response.statusCode == 429) {
        return AiConnectionResult.failure(
          code: 'http_429',
          message:
              _safeErrorMessage(response.body) ??
              'Đã vượt giới hạn yêu cầu/quota.',
        );
      }
      return AiConnectionResult.failure(
        code: 'http_${response.statusCode}',
        message:
            _safeErrorMessage(response.body) ??
            'Máy chủ từ chối yêu cầu (${response.statusCode}).',
      );
    } on TimeoutException {
      return AiConnectionResult.failure(
        code: 'timeout',
        message: 'Quá thời gian kết nối.',
      );
    } catch (e) {
      return AiConnectionResult.failure(
        code: 'network',
        message: 'Không thể kết nối máy chủ: $e',
      );
    }
  }

  Future<List<String>> listModels({
    required String apiKey,
    String? baseUrl,
  }) async {
    final base = (baseUrl == null || baseUrl.isEmpty)
        ? _defaultBaseUrl()
        : baseUrl;
    final url = Uri.parse('$base/models');
    try {
      final response = await _client
          .get(url, headers: {'Authorization': 'Bearer $apiKey'})
          .timeout(AiTimeouts.connectionTest);
      if (response.statusCode != 200) return const [];
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['data'] is List) {
        return (decoded['data'] as List)
            .whereType<Map>()
            .map((m) => (m['id'] ?? '').toString())
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
    String? baseUrl,
    double temperature = 0.7,
    int maxTokens = 1024,
    AiRequestOptions? options,
  }) async {
    if (apiKey.isEmpty) {
      return AiConnectionResult.failure(code: 'missing_api_key');
    }
    final base = (baseUrl == null || baseUrl.isEmpty)
        ? _defaultBaseUrl()
        : baseUrl;
    final url = Uri.parse('$base/chat/completions');
    final effectiveTimeout = options?.timeout ?? _defaultChatTimeout;
    final effectiveMaxTokens = options?.maxTokens ?? maxTokens;
    final stopwatch = Stopwatch()..start();
    try {
      final response = await _client
          .post(
            url,
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': model,
              'messages': [
                {'role': 'user', 'content': prompt},
              ],
              'temperature': temperature,
              'max_tokens': effectiveMaxTokens,
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

  String? _safeErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map) {
          final message = error['message'];
          if (message is String && message.trim().isNotEmpty) {
            return message.trim();
          }
        }
        final message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } catch (_) {
      // ignore malformed error responses
    }
    return null;
  }

  String _extractContent(dynamic decoded) {
    try {
      final choices = (decoded as Map<String, dynamic>)['choices'];
      if (choices is List && choices.isNotEmpty) {
        final first = choices.first;
        if (first is Map<String, dynamic>) {
          final msg = first['message'];
          if (msg is Map<String, dynamic>) {
            final content = msg['content'];
            if (content is String) return content.trim();
          }
          if (first['text'] is String) {
            return (first['text'] as String).trim();
          }
        }
      }
    } catch (_) {
      // fall through
    }
    return '';
  }
}
