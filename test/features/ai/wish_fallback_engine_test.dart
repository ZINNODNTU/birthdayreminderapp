import 'package:birthdayreminderapp/features/ai/services/ai_response_parsers.dart';
import 'package:birthdayreminderapp/features/ai/services/birthday_wish_fallback_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BirthdayWishFallbackEngine', () {
    const engine = BirthdayWishFallbackEngine();
    test('returns at least kWishTargetCount items', () {
      final items = engine.wishes(name: 'An', age: 30, language: 'vi');
      expect(items.length, greaterThanOrEqualTo(kWishTargetCount));
    });
    test('items are unique by text', () {
      final items = engine.wishes(name: 'An', age: 30, language: 'vi');
      final texts = items.map((e) => e.text).toSet();
      expect(texts.length, items.length);
    });
    test('fallback never emits raw JSON', () {
      final items = engine.wishes(name: 'An', age: 40, language: 'vi');
      for (final e in items) {
        expect(e.text, isNot(contains(RegExp(r'^\s*[\{\[]'))));
      }
    });
    test('different relationships give distinct pools', () {
      final m = engine.wishes(
        name: 'Mẹ Lan',
        gender: 'Nữ',
        age: 55,
        relationship: 'mẹ',
        language: 'vi',
      );
      final f = engine.wishes(
        name: 'Mai',
        nickname: 'Bạn Mai',
        gender: 'Nữ',
        age: 30,
        relationship: 'bạn thân',
        language: 'vi',
      );
      final mHasMotherWord = m.any((w) => w.text.contains('Mẹ'));
      final fHasFriendWord = f.any((w) => w.text.contains('Mai'));
      expect(mHasMotherWord, isTrue);
      expect(fHasFriendWord, isTrue);
      expect(m.first.text, isNot(equals(f.first.text)));
    });
  });
}
