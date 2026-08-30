/// Centralised AI client timeouts. Keep production UX tight (≤25s) so the
/// sheet never leaves the user staring at a blank card grid; fall back to
/// local deterministic content if the provider stalls.
class AiTimeouts {
  const AiTimeouts._();

  /// Probe-style call (`Trả lời đúng một từ: OK`). Short on purpose —
  /// a healthy provider responds in a few seconds.
  static const Duration connection = Duration(seconds: 15);

  /// Gift generation. The single primary request must complete within
  /// 25 seconds; anything beyond that, we fall back locally.
  static const Duration gift = Duration(seconds: 25);

  /// Wish generation. Same budget as gifts. The user only needs a quick
  /// idea — not a literary essay.
  static const Duration wish = Duration(seconds: 25);

  /// Model-list discovery used by Settings. Should be instant.
  static const Duration modelDiscovery = Duration(seconds: 15);

  /// Backward-compatible aliases for existing client paths that still
  /// reference the old names. Keep the same 25s budget — not 90s.
  static const Duration giftGeneration = Duration(seconds: 25);
  static const Duration chat = Duration(seconds: 25);
  static const Duration connectionTest = Duration(seconds: 15);
}

/// Per-request overrides. Defaults are applied by the dispatcher when
/// the caller passes `null`.
class AiRequestOptions {
  const AiRequestOptions({this.timeout, this.maxTokens});

  final Duration? timeout;
  final int? maxTokens;
}

/// Structured gift payload — exactly what the parser yields. We never
/// surface raw JSON to the user.
class GiftSuggestion {
  const GiftSuggestion({
    required this.name,
    this.reason,
    this.budget,
    this.category,
  });

  final String name;
  final String? reason;
  final String? budget;
  final String? category;
}

class GiftSuggestionResult {
  const GiftSuggestionResult({required this.items});

  final List<GiftSuggestion> items;

  bool get isEmpty => items.isEmpty;
}

/// Vietnamese age bucket used as supplemental context for the AI.
String ageGroupLabel(int age) {
  if (age <= 5) return 'trẻ nhỏ';
  if (age <= 12) return 'thiếu nhi';
  if (age <= 17) return 'thiếu niên';
  if (age <= 24) return 'người trẻ';
  if (age <= 34) return 'người trưởng thành trẻ';
  if (age <= 49) return 'trưởng thành';
  if (age <= 64) return 'trung niên';
  return 'cao tuổi';
}

class BirthdayWish {
  const BirthdayWish({required this.style, required this.text});

  final String style;
  final String text;
}

class BirthdayWishResult {
  const BirthdayWishResult({required this.wishes});

  final List<BirthdayWish> wishes;

  bool get isEmpty => wishes.isEmpty;
}

/// Supported AI provider families. The OpenAI-compatible variant
/// covers OpenAI, OpenRouter, Groq, Together, local gateways, etc.
enum AiProviderType { openAiCompatible, gemini, anthropic }

class AiProviderConfig {
  const AiProviderConfig({
    this.provider = AiProviderType.openAiCompatible,
    this.baseUrl = '',
    this.model = '',
    this.temperature = 0.7,
    this.maxTokens = 1024,
  });

  final AiProviderType provider;
  final String baseUrl;
  final String model;
  final double temperature;
  final int maxTokens;

  AiProviderConfig copyWith({
    AiProviderType? provider,
    String? baseUrl,
    String? model,
    double? temperature,
    int? maxTokens,
  }) {
    return AiProviderConfig(
      provider: provider ?? this.provider,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
    );
  }

  Map<String, dynamic> toJson() => {
    'provider': provider.name,
    'baseUrl': baseUrl,
    'model': model,
    'temperature': temperature,
    'maxTokens': maxTokens,
  };

  factory AiProviderConfig.fromJson(Map<String, dynamic> j) => AiProviderConfig(
    provider: AiProviderType.values.firstWhere(
      (e) => e.name == (j['provider'] ?? 'openAiCompatible'),
      orElse: () => AiProviderType.openAiCompatible,
    ),
    baseUrl: (j['baseUrl'] ?? '') as String,
    model: (j['model'] ?? '') as String,
    temperature: ((j['temperature'] ?? 0.7) as num).toDouble(),
    maxTokens: (j['maxTokens'] ?? 1024) as int,
  );
}

class AiConnectionResult {
  const AiConnectionResult({
    required this.ok,
    this.latencyMs,
    this.reply,
    this.errorCode,
    this.errorMessage,
  });

  final bool ok;
  final int? latencyMs;
  final String? reply;
  final String? errorCode;
  final String? errorMessage;

  static AiConnectionResult failure({
    String code = 'unknown',
    String? message,
  }) => AiConnectionResult(ok: false, errorCode: code, errorMessage: message);

  static AiConnectionResult success({
    required int latencyMs,
    required String reply,
  }) => AiConnectionResult(ok: true, latencyMs: latencyMs, reply: reply);
}

/// Masked view of an API key for UI use: sk-1234 -> sk-1234
class ApiKeyMask {
  const ApiKeyMask(this.value);
  final String value;

  static String mask(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    if (raw.length <= 8) return '***';
    return '${raw.substring(0, 4)}…${raw.substring(raw.length - 4)}';
  }

  bool get isEmpty => value.isEmpty;
  bool get isPresent => value.isNotEmpty;
}
