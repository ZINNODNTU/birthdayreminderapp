import 'dart:convert';

import '../../../models/birthday.dart';

/// Immutable AI V3 person context. Built fresh from the CURRENT
/// [Birthday] on every tap of "Gợi ý quà tặng" or "Gợi ý câu chúc".
/// Never reused across birthdays.
class BirthdayAiPersonContext {
  const BirthdayAiPersonContext({
    required this.birthdayId,
    required this.name,
    required this.nickname,
    required this.gender,
    required this.age,
    required this.relationship,
    required this.promptVersion,
  });

  final String birthdayId;
  final String name;
  final String nickname;
  final String gender;
  final int age;
  final String relationship;

  /// Bump this string every time the prompt shape or per-person
  /// inputs change. The cache key embeds it, so a bump automatically
  /// invalidates stale entries without a hard delete.
  final String promptVersion;

  /// AI V3 prompt version. Includes name + nickname + gender + age +
  /// relationship for gifts; same fields plus language for wishes.
  static const String kAiV3PromptVersion = 'gifts_v3_wishes_v3';

  /// Build a V3 context directly from a [Birthday]. Convenience for the
  /// service and the tests — never call this from a global; build it
  /// per tap.
  factory BirthdayAiPersonContext.fromBirthday(Birthday b) {
    return BirthdayAiPersonContext(
      birthdayId: b.id,
      name: b.name.trim(),
      nickname: (b.nickname ?? '').trim(),
      gender: (b.gender ?? '').trim(),
      age: _computeAge(b.solarBirthday, DateTime.now()),
      relationship:
          (b.relationship ?? '').trim().isEmpty
              ? 'người quen'
              : b.relationship!.trim(),
      promptVersion: kAiV3PromptVersion,
    );
  }

  /// Deterministic FNV-1a 32-bit hash of the person-significant fields.
  /// Used as the per-person portion of every AI V3 cache key. Two
  /// distinct birthdays with the same age+gender but a different name
  /// OR relationship OR nickname MUST produce a different context hash.
  String get contextHash {
    // Concatenate normalised values. Trim and lower-case only matter
    // for hash stability, not for display — the gift/wish builder uses
    // the originals.
    final parts = <String>[
      _norm(name),
      _norm(nickname),
      _norm(gender),
      age.toString(),
      _norm(relationship),
    ];
    final input = parts.join('|');
    // FNV-1a 32-bit.
    var hash = 0x811c9dc5;
    final bytes = utf8.encode(input);
    for (final b in bytes) {
      hash ^= b;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  /// Canonical cache key fragment for a feature. Format:
  ///   `ai:v3:<feature>:<birthdayId>:<contextHash>:<provider>:<model>[:<language>]`
  String cacheKey({
    required String feature,
    required String provider,
    required String model,
    String? language,
  }) {
    final langPart = (language == null || language.isEmpty) ? '' : ':$language';
    return 'ai:v3:$feature:$birthdayId:$contextHash:$provider:$model$langPart';
  }

  static String _norm(String s) => s.trim().toLowerCase();

  static int _computeAge(DateTime solar, DateTime now) {
    int age = now.year - solar.year;
    if (now.month < solar.month ||
        (now.month == solar.month && now.day < solar.day)) {
      age--;
    }
    return age;
  }
}
