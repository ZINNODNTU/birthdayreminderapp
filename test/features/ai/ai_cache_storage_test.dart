import 'package:birthdayreminderapp/features/ai/data/ai_cache_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'writeGifts then readGifts returns items when context matches',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final s = AiCacheStorage(prefs);
      final items = [
        {'name': 'A', 'reason': 'r', 'budget': 'b', 'category': 'c'},
        {'name': 'B'},
      ];
      await s.writeGifts(
        birthdayId: 'id1',
        contextHash: 'aaaa1111',
        provider: 'gemini',
        model: 'gemini-1.5',
        items: items,
      );
      final read = s.readGifts(
        birthdayId: 'id1',
        contextHash: 'aaaa1111',
        provider: 'gemini',
        model: 'gemini-1.5',
      );
      expect(read, isNotNull);
      expect(read!.length, 2);
    },
  );

  test('readGifts returns null on contextHash mismatch', () async {
    final prefs = await SharedPreferences.getInstance();
    final s = AiCacheStorage(prefs);
    await s.writeGifts(
      birthdayId: 'id1',
      contextHash: 'aaaa1111',
      provider: 'gemini',
      model: 'gemini-1.5',
      items: const [
        {'name': 'A'},
      ],
    );
    final read = s.readGifts(
      birthdayId: 'id1',
      contextHash: 'bbbb2222',
      provider: 'gemini',
      model: 'gemini-1.5',
    );
    expect(read, isNull);
  });

  test('writeWishes does NOT contain any api key field', () async {
    final prefs = await SharedPreferences.getInstance();
    final s = AiCacheStorage(prefs);
    await s.writeWishes(
      birthdayId: 'id1',
      contextHash: 'abcd',
      language: 'vi',
      provider: 'gemini',
      model: 'gemini-1.5',
      items: const [
        {'style': 'Ngắn gọn', 'text': 'X'},
      ],
    );
    final raw = prefs.getString('ai_cache_wishes_v3');
    expect(raw, isNotNull);
    expect(raw!.toLowerCase(), isNot(contains('api')));
    expect(raw.toLowerCase(), isNot(contains('authorization')));
    expect(raw.toLowerCase(), isNot(contains('bearer')));
  });

  test('readWishes returns null after TTL passes', () async {
    SharedPreferences.setMockInitialValues({
      'ai_cache_wishes_v3':
          '{"savedAt":"2020-01-01T00:00:00.000Z","inputs":{"birthdayId":"id1","contextHash":"abcd","promptVersion":"gifts_v3_wishes_v3","language":"vi","provider":"gemini","model":"m"},"items":[{"text":"A"}]}',
    });
    final prefs = await SharedPreferences.getInstance();
    final s = AiCacheStorage(prefs);
    final r = s.readWishes(
      birthdayId: 'id1',
      contextHash: 'abcd',
      language: 'vi',
      provider: 'gemini',
      model: 'm',
    );
    expect(r, isNull);
  });

  test('clear() wipes v3 cache', () async {
    final prefs = await SharedPreferences.getInstance();
    final s = AiCacheStorage(prefs);
    await s.writeGifts(
      birthdayId: 'id1',
      contextHash: 'h',
      provider: 'p',
      model: 'm',
      items: const [],
    );
    await s.clear();
    expect(prefs.getString('ai_cache_gifts_v3'), isNull);
  });
}
