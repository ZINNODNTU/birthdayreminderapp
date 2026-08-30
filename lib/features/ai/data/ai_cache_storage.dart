import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local cache for AI feature results. Keys are deterministic across
/// devices (and across rebuilds) so opening the sheet twice in a row
/// returns the cached payload with zero network calls.
///
/// The cache is NEVER allowed to contain API keys, authorization
/// headers, prompt text, or photo bytes. Only the parsed items
/// (`List<GiftSuggestion>` / `List<BirthdayWish>`) are stored, keyed by
/// the public inputs that determined them.
///
/// AI V3 (current):
///   * Storage keys bumped to `ai_cache_gifts_v3` / `ai_cache_wishes_v3`.
///   * Inputs include `contextHash` (per-person) — two different people
///     with the same age+gender MUST NOT share a cache entry.
///   * Gift inputs include `relationship`; wish inputs unchanged in shape
///     but keyed through the same hash mechanism.
///   * `promptVersion` is embedded so a future prompt change
///     automatically invalidates everything without a destructive flush.
class AiCacheStorage {
  AiCacheStorage(this._prefs);

  /// 24-hour TTL — long enough that reopening a birthday sheet returns
  /// the previous answer instantly, short enough that the user always
  /// sees fresh content when they explicitly hit "Tạo lại".
  static const Duration ttl = Duration(hours: 24);

  static const String _giftsKey = 'ai_cache_gifts_v3';
  static const String _wishesKey = 'ai_cache_wishes_v3';

  static const String _currentPromptVersion = 'gifts_v3_wishes_v3';

  final SharedPreferences _prefs;

  /// Returns a previously cached gift payload if it is still within TTL,
  /// produced by the same provider/model, and the person context matches.
  List<Map<String, dynamic>>? readGifts({
    required String birthdayId,
    required String contextHash,
    required String provider,
    required String model,
  }) => _read(
    key: _giftsKey,
    birthdayId: birthdayId,
    contextHash: contextHash,
    provider: provider,
    model: model,
  );

  /// Returns a previously cached wish payload.
  List<Map<String, dynamic>>? readWishes({
    required String birthdayId,
    required String contextHash,
    required String language,
    required String provider,
    required String model,
  }) => _read(
    key: _wishesKey,
    birthdayId: birthdayId,
    contextHash: contextHash,
    provider: provider,
    model: model,
    language: language,
  );

  /// Caches the gift payload keyed under the current person context.
  Future<void> writeGifts({
    required String birthdayId,
    required String contextHash,
    required String provider,
    required String model,
    required List<Map<String, dynamic>> items,
  }) async {
    await _write(
      key: _giftsKey,
      birthdayId: birthdayId,
      contextHash: contextHash,
      provider: provider,
      model: model,
      items: items,
    );
  }

  /// Caches the wish payload keyed under the current person context.
  Future<void> writeWishes({
    required String birthdayId,
    required String contextHash,
    required String language,
    required String provider,
    required String model,
    required List<Map<String, dynamic>> items,
  }) async {
    await _write(
      key: _wishesKey,
      birthdayId: birthdayId,
      contextHash: contextHash,
      language: language,
      provider: provider,
      model: model,
      items: items,
    );
  }

  /// Wipe everything — used by tests and Settings → "Clear AI cache".
  Future<void> clear() async {
    await _prefs.remove(_giftsKey);
    await _prefs.remove(_wishesKey);
    // Also clear v2 entries left over from older app versions.
    await _prefs.remove('ai_cache_gifts_v1');
    await _prefs.remove('ai_cache_wishes_v1');
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>>? _read({
    required String key,
    required String birthdayId,
    required String contextHash,
    required String provider,
    required String model,
    String? language,
  }) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    Map<String, dynamic> outer;
    try {
      outer = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
    final savedAt =
        DateTime.tryParse((outer['savedAt'] as String?) ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    if (DateTime.now().difference(savedAt) >= ttl) return null;
    final inputs = (outer['inputs'] as Map<String, dynamic>?) ?? const {};
    if (!inputsEqual(
      lhs: inputs,
      birthdayId: birthdayId,
      contextHash: contextHash,
      language: language,
      provider: provider,
      model: model,
    )) {
      return null;
    }
    final items = (outer['items'] as List?) ?? const [];
    return items
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
  }

  Future<void> _write({
    required String key,
    required String birthdayId,
    required String contextHash,
    required String provider,
    required String model,
    String? language,
    required List<Map<String, dynamic>> items,
  }) async {
    final outer = <String, dynamic>{
      'savedAt': DateTime.now().toIso8601String(),
      'inputs': <String, dynamic>{
        'birthdayId': birthdayId,
        'contextHash': contextHash,
        'promptVersion': _currentPromptVersion,
        'language': language,
        'provider': provider,
        'model': model,
      },
      'items': items,
    };
    await _prefs.setString(key, jsonEncode(outer));
  }

  static bool inputsEqual({
    required Map<String, dynamic> lhs,
    required String birthdayId,
    required String contextHash,
    required String provider,
    required String model,
    String? language,
  }) {
    bool eqNullable(Object? a, Object? b) => (a ?? '') == (b ?? '');
    return eqNullable(lhs['birthdayId'], birthdayId) &&
        eqNullable(lhs['contextHash'], contextHash) &&
        eqNullable(lhs['promptVersion'], _currentPromptVersion) &&
        eqNullable(lhs['language'], language ?? lhs['language']) &&
        eqNullable(lhs['provider'], provider) &&
        eqNullable(lhs['model'], model);
  }
}
