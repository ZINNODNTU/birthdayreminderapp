import '../domain/ai_provider.dart';
import 'anthropic_client.dart';
import 'gemini_client.dart';
import 'openai_compatible_client.dart';

/// Dispatches to the right provider-specific client based on the
/// currently selected [AiProviderType]. API keys never leave this
/// layer — callers receive only [AiConnectionResult] outputs.
class AiClient {
  AiClient({
    OpenAiCompatibleClient? openAi,
    GeminiClient? gemini,
    AnthropicClient? anthropic,
  }) : _openAi = openAi ?? OpenAiCompatibleClient(),
       _gemini = gemini ?? GeminiClient(),
       _anthropic = anthropic ?? AnthropicClient();

  final OpenAiCompatibleClient _openAi;
  final GeminiClient _gemini;
  final AnthropicClient _anthropic;

  Future<AiConnectionResult> testConnection({
    required AiProviderConfig config,
    required String apiKey,
  }) {
    switch (config.provider) {
      case AiProviderType.gemini:
        return _gemini.testConnection(apiKey: apiKey, model: config.model);
      case AiProviderType.anthropic:
        return _anthropic.testConnection(apiKey: apiKey, model: config.model);
      case AiProviderType.openAiCompatible:
        return _openAi.testConnection(
          apiKey: apiKey,
          model: config.model,
          baseUrl: config.baseUrl,
        );
    }
  }

  Future<List<String>> listModels({
    required AiProviderConfig config,
    required String apiKey,
  }) {
    switch (config.provider) {
      case AiProviderType.openAiCompatible:
        return _openAi.listModels(apiKey: apiKey, baseUrl: config.baseUrl);
      case AiProviderType.gemini:
        return _gemini.listModels(apiKey: apiKey);
      case AiProviderType.anthropic:
        return Future.value(const <String>[]);
    }
  }

  Future<AiConnectionResult> chat({
    required AiProviderConfig config,
    required String apiKey,
    required String prompt,
    AiRequestOptions? options,
  }) {
    switch (config.provider) {
      case AiProviderType.gemini:
        return _gemini.chat(
          apiKey: apiKey,
          model: config.model,
          prompt: prompt,
          options: options,
        );
      case AiProviderType.anthropic:
        return _anthropic.chat(
          apiKey: apiKey,
          model: config.model,
          prompt: prompt,
          options: options,
        );
      case AiProviderType.openAiCompatible:
        return _openAi.chat(
          apiKey: apiKey,
          model: config.model,
          prompt: prompt,
          baseUrl: config.baseUrl,
          temperature: config.temperature,
          maxTokens: config.maxTokens,
          options: options,
        );
    }
  }
}
