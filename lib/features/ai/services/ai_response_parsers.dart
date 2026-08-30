import 'dart:convert';

import '../domain/ai_provider.dart';

const int kGiftTargetCount = 10;
const int kWishTargetCount = 10;
const int kAiMaxRepairRequests = 1;

/// Robust JSON extractors for the structured AI outputs we expect.
///
/// Real model outputs frequently:
///  * wrap the JSON in markdown fences
///  * lead with prose such as "Đây là gợi ý:"
///  * return truncated JSON when the model hits its token cap mid-array
///  * or just return a single unterminated object
///
/// We handle every case explicitly so that the UI never sees raw JSON
/// rendered as a "gift" or "wish" card. Anything that doesn't parse to
/// a valid [GiftSuggestion] / [BirthdayWish] is silently dropped.
class GiftSuggestionsParser {
  const GiftSuggestionsParser();

  GiftSuggestionResult parse(String? raw) {
    return GiftSuggestionResult(items: _dedupe(_parseItems(raw)));
  }

  List<GiftSuggestion> _parseItems(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    final normalized = normalizeAiJson(raw);
    final list = _extractGiftsList(normalized, rawFallback: raw);
    if (list == null || list.isEmpty) {
      return _fallbackLines(raw);
    }
    final out = <GiftSuggestion>[];
    for (final raw2 in list) {
      if (raw2 is! Map) continue;
      final m = Map<String, dynamic>.from(raw2);
      // The compact prompt schema uses single-letter keys. Accept both:
      //   long:   name / reason / budget / category
      //   short:  n    / r      / b      / c
      final name = _stringOrNull(m['name']) ?? _stringOrNull(m['n']);
      if (name == null || name.trim().isEmpty) continue;
      if (looksLikeRawJson(name)) continue;
      out.add(
        GiftSuggestion(
          name: name.trim(),
          reason: _stringOrNull(m['reason']) ?? _stringOrNull(m['r'])?.trim(),
          budget: _stringOrNull(m['budget']) ?? _stringOrNull(m['b'])?.trim(),
          category:
              _stringOrNull(m['category']) ?? _stringOrNull(m['c'])?.trim(),
        ),
      );
      if (out.length >= kGiftTargetCount) break;
    }
    return out.isEmpty ? _fallbackLines(raw) : out;
  }

  /// Walk the raw reply and collect every plausible gift list:
  ///   1. Try a clean `jsonDecode` first.
  ///   2. On failure, scan the character stream for the substring
  ///      `gifts`:`[` and harvest complete `{...}` children from the
  ///      matching array. Each child is decoded independently.
  ///   3. Return `null` if the reply doesn't even look like JSON.
  List<dynamic>? _extractGiftsList(
    String normalized, {
    required String rawFallback,
  }) {
    if (normalized.trim().isEmpty) return null;
    // 1. Clean decode path. Accept both long and compact top-level keys.
    try {
      final decoded = jsonDecode(normalized);
      if (decoded is Map<String, dynamic>) {
        final list = decoded['gifts'] ?? decoded['g'];
        if (list is List && list.isNotEmpty) return list;
      }
      if (decoded is List) return decoded;
    } catch (_) {
      // fall through to recovery
    }
    // 2. Recovery for truncated / malformed JSON. Try `gifts` first
    //    (long shape), then `g` (compact shape).
    final recovered = recoverArrayChildren(normalized, 'gifts');
    if (recovered.isNotEmpty) return recovered;
    final recoveredCompact = recoverArrayChildren(normalized, '"g"');
    if (recoveredCompact.isNotEmpty) return recoveredCompact;
    // 3. Bail: looks like JSON but cannot be salvaged.
    if (looksLikeJson(rawFallback)) return const [];
    return null;
  }

  List<GiftSuggestion> _fallbackLines(String raw) {
    // Hard guard: never let a single line of raw JSON become a "gift".
    final lines = raw
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.replaceFirst(RegExp(r'^\s*[-*\d\.)]+\s*'), '').trim())
        .where((l) => l.isNotEmpty)
        .where((l) => !looksLikeRawJson(l))
        .toList(growable: false);
    return lines
        .take(kGiftTargetCount)
        .map((l) => GiftSuggestion(name: l))
        .toList(growable: false);
  }

  List<GiftSuggestion> _dedupe(List<GiftSuggestion> input) {
    final seen = <String>{};
    final out = <GiftSuggestion>[];
    for (final item in input) {
      final key = _normalize(item.name);
      if (key.isEmpty) continue;
      if (seen.add(key)) out.add(item);
      if (out.length >= kGiftTargetCount) break;
    }
    return out;
  }
}

class BirthdayWishParser {
  const BirthdayWishParser();

  BirthdayWishResult parse(String? raw) {
    return BirthdayWishResult(wishes: _dedupe(_parseWishes(raw)));
  }

  List<BirthdayWish> _parseWishes(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    final normalized = normalizeAiJson(raw);
    final list = _extractWishesList(normalized, rawFallback: raw);
    if (list == null || list.isEmpty) {
      return _fallbackLines(raw);
    }
    final out = <BirthdayWish>[];
    for (final raw2 in list) {
      if (raw2 is! Map) continue;
      final m = Map<String, dynamic>.from(raw2);
      // Long keys (style/text) and compact keys (s/t) both accepted.
      final text = _stringOrNull(m['text']) ?? _stringOrNull(m['t']);
      if (text == null || text.trim().isEmpty) continue;
      if (looksLikeRawJson(text)) continue;
      out.add(
        BirthdayWish(
          style:
              (_stringOrNull(m['style']) ?? _stringOrNull(m['s']))?.trim() ??
              'Câu chúc',
          text: text.trim(),
        ),
      );
      if (out.length >= kWishTargetCount) break;
    }
    return out.isEmpty ? _fallbackLines(raw) : out;
  }

  List<dynamic>? _extractWishesList(
    String normalized, {
    required String rawFallback,
  }) {
    if (normalized.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(normalized);
      if (decoded is Map<String, dynamic>) {
        final list = decoded['wishes'] ?? decoded['w'];
        if (list is List && list.isNotEmpty) return list;
      }
      if (decoded is List) return decoded;
    } catch (_) {
      // fall through
    }
    final recovered = recoverArrayChildren(normalized, 'wishes');
    if (recovered.isNotEmpty) return recovered;
    final recoveredCompact = recoverArrayChildren(normalized, '"w"');
    if (recoveredCompact.isNotEmpty) return recoveredCompact;
    if (looksLikeJson(rawFallback)) return const [];
    return null;
  }

  List<BirthdayWish> _fallbackLines(String raw) {
    final lines = raw
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.replaceFirst(RegExp(r'^\s*[-*\d\.)]+\s*'), '').trim())
        .where((l) => l.isNotEmpty)
        .where((l) => !looksLikeRawJson(l))
        .toList(growable: false);
    return lines
        .take(kWishTargetCount)
        .map((l) => BirthdayWish(style: 'Câu chúc', text: l))
        .toList(growable: false);
  }

  List<BirthdayWish> _dedupe(List<BirthdayWish> input) {
    final seen = <String>{};
    final out = <BirthdayWish>[];
    for (final item in input) {
      final key = _normalize(item.text);
      if (key.isEmpty) continue;
      if (seen.add(key)) out.add(item);
      if (out.length >= kWishTargetCount) break;
    }
    return out;
  }
}

/// Public normalize helper. Strips BOM, leading prose before the first
/// `{` and trailing prose after the matching `}`. Preserves escapes
/// inside JSON strings.
///
/// Used by [GiftSuggestionsParser] and [BirthdayWishParser] and kept
/// public so other callers (e.g. tests) can assert behaviour.
String normalizeAiJson(String raw) {
  var s = raw;
  // Strip BOM.
  if (s.isNotEmpty && s.codeUnitAt(0) == 0xFEFF) {
    s = s.substring(1);
  }
  // Strip ```json / ``` fences (keep inner content).
  s = s.replaceAll(RegExp(r'```(?:json)?', multiLine: true), '');
  s = s.replaceAll(RegExp(r'```'), '');
  // Drop leading prose before the first `{`.
  final firstBrace = s.indexOf('{');
  if (firstBrace > 0) s = s.substring(firstBrace);
  // Drop trailing prose after the matching `}`. We don't try to count
  // braces (escapes inside strings make that unreliable). Instead, we
  // find the *last* unmatched closing brace at depth 0 by scanning.
  if (s.endsWith('}') || s.contains('}')) {
    final last = _lastClosingBrace(s);
    if (last > 0) s = s.substring(0, last + 1);
  }
  return s.trim();
}

int _lastClosingBrace(String s) {
  bool inString = false;
  bool escape = false;
  int depth = 0;
  int lastAtZero = -1;
  for (var i = 0; i < s.length; i++) {
    final c = s[i];
    if (escape) {
      escape = false;
      continue;
    }
    if (c == r'\\') {
      if (inString) escape = true;
      continue;
    }
    if (c == '"') {
      inString = !inString;
      continue;
    }
    if (inString) continue;
    if (c == '{') depth++;
    if (c == '}') {
      depth--;
      if (depth == 0) lastAtZero = i;
    }
  }
  return lastAtZero;
}

/// Hard guard — true when [value] smells like unparsed JSON / markdown
/// we should never render as user-facing content.
bool looksLikeRawJson(String value) {
  final v = value.trim();
  if (v.isEmpty) return false;
  if (v.contains('```json') || v.contains('```')) return true;
  if (v.startsWith('{') || v.startsWith('[')) return true;
  if (v.contains('{"gifts"') ||
      v.contains('{"wishes"') ||
      v.contains('"name":') ||
      v.contains('"style":') ||
      v.contains('"text":')) {
    return true;
  }
  return false;
}

bool looksLikeJson(String raw) {
  final v = raw.trim();
  return v.startsWith('{') || v.startsWith('[') || v.contains('```json');
}

/// Walk [source] looking for `"<key>":[` and harvest every complete
/// top-level `{...}` child object from the matching array.
///
/// Each child is decoded independently with [jsonDecode] — incomplete
/// trailing objects are silently dropped.
List<dynamic> recoverArrayChildren(String source, String key) {
  final list = <dynamic>[];
  final needle = '"$key":';
  var i = source.indexOf(needle);
  if (i < 0) return list;
  i += needle.length;
  // Skip whitespace + optional `[`.
  while (i < source.length && _isJsonWs(source[i])) {
    i++;
  }
  if (i >= source.length || source[i] != '[') return list;
  i++; // consume `[`
  while (i < source.length) {
    while (i < source.length && _isJsonWs(source[i])) {
      i++;
    }
    if (i >= source.length) break;
    if (source[i] != '{') {
      i++;
      continue;
    }
    final end = _scanObjectEnd(source, i);
    if (end <= i) break;
    final chunk = source.substring(i, end + 1);
    try {
      final decoded = jsonDecode(chunk);
      if (decoded != null) list.add(decoded);
    } catch (_) {
      // ignore broken object
    }
    i = end + 1;
    while (i < source.length && _isJsonWs(source[i])) {
      i++;
    }
    if (i < source.length && source[i] == ',') i++;
  }
  return list;
}

bool _isJsonWs(String c) => c == ' ' || c == '\n' || c == '\r' || c == '\t';

int _scanObjectEnd(String s, int start) {
  var depth = 0;
  var inString = false;
  var escape = false;
  for (var i = start; i < s.length; i++) {
    final c = s[i];
    if (escape) {
      escape = false;
      continue;
    }
    if (c == r'\\') {
      if (inString) escape = true;
      continue;
    }
    if (c == '"') {
      inString = !inString;
      continue;
    }
    if (inString) continue;
    if (c == '{') depth++;
    if (c == '}') {
      depth--;
      if (depth == 0) return i;
    }
  }
  return -1;
}

String? _stringOrNull(dynamic v) {
  if (v is String) return v;
  if (v == null) return null;
  return v.toString();
}

String _normalize(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
