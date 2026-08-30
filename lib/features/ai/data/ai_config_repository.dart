import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/ai_provider.dart';

/// Result of a secure-storage operation. Only a sanitised success/failure
/// flag plus the byte length is exposed — never the secret itself.
class SecureKeyResult {
  const SecureKeyResult({required this.ok, this.length, this.errorCode});

  factory SecureKeyResult.success(int length) =>
      SecureKeyResult(ok: true, length: length);

  factory SecureKeyResult.failure(String code) =>
      SecureKeyResult(ok: false, errorCode: code);

  final bool ok;
  final int? length;
  final String? errorCode;
}

/// Persists the AI provider configuration.
///
/// Secrets (API keys) are stored in [FlutterSecureStorage] backed by
/// the Android Keystore; everything else lives in [SharedPreferences].
class AiConfigRepository {
  AiConfigRepository({
    required SharedPreferences prefs,
    FlutterSecureStorage? secureStorage,
  }) : _prefs = prefs,
       _secure = secureStorage ?? const FlutterSecureStorage();

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secure;

  static const String _configKey = 'ai_provider_config_v1';

  static const Map<AiProviderType, String> _apiKeyAliases = {
    AiProviderType.openAiCompatible: 'ai_api_key_openai_compatible',
    AiProviderType.gemini: 'ai_api_key_gemini',
    AiProviderType.anthropic: 'ai_api_key_anthropic',
  };

  AiProviderConfig loadConfig() {
    final raw = _prefs.getString(_configKey);
    if (raw == null || raw.isEmpty) return const AiProviderConfig();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return AiProviderConfig.fromJson(decoded);
      }
    } catch (_) {
      // fall through to default
    }
    return const AiProviderConfig();
  }

  Future<void> saveConfig(AiProviderConfig config) async {
    await _prefs.setString(_configKey, jsonEncode(config.toJson()));
  }

  Future<SecureKeyResult> writeApiKey(
    AiProviderType provider,
    String key,
  ) async {
    if (key.isEmpty) {
      try {
        await _secure.delete(key: _apiKeyAliases[provider]!);
        return const SecureKeyResult(ok: true, length: 0);
      } catch (e) {
        _logError(provider, e);
        return SecureKeyResult.failure('secure_storage_error');
      }
    }
    try {
      await _secure.write(key: _apiKeyAliases[provider]!, value: key);
      return SecureKeyResult.success(key.length);
    } catch (e) {
      _logError(provider, e);
      return SecureKeyResult.failure(_classifyError(e));
    }
  }

  Future<String?> readApiKey(AiProviderType provider) async {
    try {
      return await _secure.read(key: _apiKeyAliases[provider]!);
    } catch (e) {
      _logError(provider, e);
      return null;
    }
  }

  Future<bool> hasApiKey(AiProviderType provider) async {
    final value = await readApiKey(provider);
    return value != null && value.isNotEmpty;
  }

  Future<SecureKeyResult> clearApiKey(AiProviderType provider) async {
    try {
      await _secure.delete(key: _apiKeyAliases[provider]!);
      return const SecureKeyResult(ok: true, length: 0);
    } catch (e) {
      _logError(provider, e);
      return SecureKeyResult.failure(_classifyError(e));
    }
  }

  void _logError(AiProviderType p, Object e) {
    if (kDebugMode) {
      debugPrint(
        '[AiConfig] secure storage error for '
        '${p.name}: ${e.runtimeType}',
      );
    }
  }

  String _classifyError(Object e) {
    if (e is MissingPluginException) return 'secure_storage_error';
    if (e is PlatformException) return 'secure_storage_error';
    return 'unknown';
  }
}
