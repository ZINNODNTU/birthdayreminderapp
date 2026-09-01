import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:birthdayreminderapp/features/ai/data/ai_cache_storage.dart';
import 'package:birthdayreminderapp/features/ai/domain/birthday_ai_person_context.dart';
import 'package:birthdayreminderapp/features/ai/services/birthday_wish_fallback_engine.dart';
import 'package:birthdayreminderapp/features/ai/services/gift_fallback_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BirthdayAiPersonContext V3', () {
    test('contextHash differs across two people with same age + gender', () {
      final lover = _make(
        id: 'a',
        name: 'Mai Anh',
        nickname: 'Mài',
        gender: 'nữ',
        age: 22,
        relationship: 'người yêu',
      );
      final colleague = _make(
        id: 'b',
        name: 'Mai Anh',
        nickname: 'Mài',
        gender: 'nữ',
        age: 22,
        relationship: 'đồng nghiệp',
      );
      expect(lover.contextHash, isNot(equals(colleague.contextHash)));
    });

    test('contextHash identical for identical context fields', () {
      final a = _make(
        id: 'a',
        name: 'Lan',
        nickname: '',
        gender: 'nữ',
        age: 25,
        relationship: 'bạn thân',
      );
      final b = _make(
        id: 'b',
        name: 'lan',
        nickname: '',
        gender: 'nữ',
        age: 25,
        relationship: 'bạn thân',
      );
      expect(a.contextHash, equals(b.contextHash));
    });

    test('edit invalidates cache via contextHash change', () {
      final before = _make(
        id: 'a',
        name: 'Hương',
        nickname: 'Hương bé',
        gender: 'nữ',
        age: 30,
        relationship: 'chị gái',
      );
      final after = _make(
        id: 'a',
        name: 'Hương',
        nickname: '',
        gender: 'nữ',
        age: 30,
        relationship: 'chị gái',
      );
      expect(before.contextHash, isNot(equals(after.contextHash)));
    });

    test('cache key embeds contextHash + provider + model + feature', () {
      final ctx = _make(
        id: 'a',
        name: 'A',
        nickname: '',
        gender: 'nam',
        age: 30,
        relationship: 'bạn',
      );
      final k = ctx.cacheKey(
        feature: 'gift',
        provider: 'openai',
        model: 'gpt-4o-mini',
      );
      expect(k, contains('ai:v3:gift'));
      expect(k, contains(ctx.birthdayId));
      expect(k, contains(ctx.contextHash));
    });
  });

  group('AiCacheStorage V3', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('read returns null when contextHash differs', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = AiCacheStorage(prefs);
      await store.writeGifts(
        birthdayId: 'a',
        contextHash: 'aaaa1111',
        provider: 'openai',
        model: 'gpt-4o-mini',
        items: [
          {'name': 'G1', 'reason': 'r', 'budget': 'b', 'category': 'c'},
        ],
      );
      final got = store.readGifts(
        birthdayId: 'a',
        contextHash: 'bbbb2222',
        provider: 'openai',
        model: 'gpt-4o-mini',
      );
      expect(got, isNull);
    });

    test('read returns items when contextHash matches', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = AiCacheStorage(prefs);
      await store.writeGifts(
        birthdayId: 'a',
        contextHash: 'abc123',
        provider: 'openai',
        model: 'gpt-4o-mini',
        items: [
          {'name': 'G1', 'reason': 'r', 'budget': 'b', 'category': 'c'},
        ],
      );
      final got = store.readGifts(
        birthdayId: 'a',
        contextHash: 'abc123',
        provider: 'openai',
        model: 'gpt-4o-mini',
      );
      expect(got, isNotNull);
      expect(got!.length, 1);
    });

    test('TTL expires stale entries', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = AiCacheStorage(prefs);
      await store.writeGifts(
        birthdayId: 'a',
        contextHash: 'abcd',
        provider: 'openai',
        model: 'gpt-4o-mini',
        items: const [],
      );
      // Force-expire by rewriting the savedAt inside the same prefs.
      final raw = prefs.getString('ai_cache_gifts_v3');
      expect(raw, isNotNull);
      final mutated = raw!.replaceFirst(
        RegExp(r'"savedAt":"[^"]+"'),
        '"savedAt":"2000-01-01T00:00:00.000"',
      );
      await prefs.setString('ai_cache_gifts_v3', mutated);
      final got = store.readGifts(
        birthdayId: 'a',
        contextHash: 'abcd',
        provider: 'openai',
        model: 'gpt-4o-mini',
      );
      expect(got, isNull);
    });
  });

  group('GiftFallbackEngine V3', () {
    const engine = GiftFallbackEngine();

    test('lover 22-year-old gets personal adult suggestions', () {
      final items = engine.suggestions(
        gender: 'nữ',
        age: 22,
        relationship: 'người yêu',
        name: 'Mai',
        nickname: 'Mài',
      );
      expect(items.length, greaterThanOrEqualTo(10));
      final joined = items.map((e) => e.reason ?? '').join(' ').toLowerCase();
      expect(joined.contains('mai') || joined.contains('mài'), isTrue);
    });

    test('colleague 22-year-old gets professional suggestions', () {
      final items = engine.suggestions(
        gender: 'nữ',
        age: 22,
        relationship: 'đồng nghiệp',
        name: 'Mai',
        nickname: '',
      );
      expect(items.length, greaterThanOrEqualTo(10));
      final cats = items.map((e) => (e.category ?? '').toLowerCase()).toSet();
      // Colleague bank should lean toward work-related categories.
      expect(cats.contains('đồ dùng') || cats.contains('sách'), isTrue);
    });

    test('1-year-old child gets safe-toy suggestions', () {
      final items = engine.suggestions(
        gender: 'nam',
        age: 1,
        relationship: 'con',
        name: 'Bé Bo',
        nickname: '',
      );
      expect(items.length, greaterThanOrEqualTo(10));
      final cats = items.map((e) => (e.category ?? '').toLowerCase()).toSet();
      expect(cats.contains('đồ chơi'), isTrue);
    });

    test('empty inputs still produce 10 items', () {
      final items = engine.suggestions();
      expect(items.length, greaterThanOrEqualTo(10));
    });
  });

  group('BirthdayWishFallbackEngine V3', () {
    const engine = BirthdayWishFallbackEngine();

    test('lover wishes use name and are affectionate', () {
      final list = engine.wishes(
        name: 'Mai Anh',
        nickname: 'Mài',
        gender: 'nữ',
        age: 22,
        relationship: 'người yêu',
        language: 'vi',
      );
      expect(list.length, greaterThanOrEqualTo(10));
      final usesName =
          list
              .where((w) => w.text.contains('Mai') || w.text.contains('Mài'))
              .length;
      expect(usesName, greaterThanOrEqualTo(7));
    });

    test('colleague wishes remain professional, name optional', () {
      final list = engine.wishes(
        name: 'Lan',
        nickname: '',
        gender: 'nữ',
        age: 30,
        relationship: 'đồng nghiệp',
        language: 'vi',
      );
      expect(list.length, greaterThanOrEqualTo(10));
      for (final w in list) {
        expect(w.text.contains('em'), isFalse, reason: w.text);
      }
    });

    test('child wishes are simple and warm', () {
      final list = engine.wishes(
        name: 'Bé Bo',
        nickname: 'Bo',
        gender: 'nam',
        age: 5,
        relationship: 'con',
        language: 'vi',
      );
      expect(list.length, greaterThanOrEqualTo(10));
      // With nickname set, the engine prefers the nickname.
      final usesName = list.where((w) => w.text.contains('Bo')).length;
      expect(usesName, greaterThan(0));
    });

    test('parent wishes use ơi tone', () {
      final list = engine.wishes(
        name: 'Mẹ',
        nickname: '',
        gender: 'nữ',
        age: 55,
        relationship: 'mẹ',
        language: 'vi',
      );
      expect(list.length, greaterThanOrEqualTo(10));
      final mentionsMother =
          list
              .where((w) => w.text.contains('Mẹ') || w.text.contains('mẹ'))
              .length;
      expect(mentionsMother, greaterThanOrEqualTo(5));
    });
  });
}

BirthdayAiPersonContext _make({
  required String id,
  required String name,
  required String nickname,
  required String gender,
  required int age,
  required String relationship,
}) {
  // We bypass `fromBirthday` (which derives age from solarBirthday) so
  // tests stay deterministic across years.
  return BirthdayAiPersonContext(
    birthdayId: id,
    name: name,
    nickname: nickname,
    gender: gender,
    age: age,
    relationship: relationship,
    promptVersion: BirthdayAiPersonContext.kAiV3PromptVersion,
  );
}
