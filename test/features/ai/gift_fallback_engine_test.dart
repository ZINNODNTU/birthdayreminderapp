import 'package:birthdayreminderapp/features/ai/services/ai_response_parsers.dart';
import 'package:birthdayreminderapp/features/ai/services/gift_fallback_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GiftFallbackEngine V3', () {
    const engine = GiftFallbackEngine();

    test('returns at least kGiftTargetCount items for a toddler', () {
      final items = engine.suggestions(gender: 'nam', age: 2);
      expect(items.length, greaterThanOrEqualTo(kGiftTargetCount));
    });

    test('returns at least kGiftTargetCount items for an elder', () {
      final items = engine.suggestions(gender: 'nữ', age: 70);
      expect(items.length, greaterThanOrEqualTo(kGiftTargetCount));
    });

    test('items are unique by name', () {
      final items = engine.suggestions(gender: 'nam', age: 30);
      final names = items.map((e) => e.name.toLowerCase()).toSet();
      expect(names.length, items.length);
    });

    test('age bucketing falls back to adult for unknown age', () {
      final items = engine.suggestions(gender: 'nam');
      expect(items.length, greaterThanOrEqualTo(kGiftTargetCount));
    });

    test('budget is non-empty VNĐ text', () {
      final items = engine.suggestions(gender: 'nam', age: 25);
      for (final e in items) {
        expect(e.budget, isNotNull);
        expect(e.budget!.contains('đ'), isTrue);
      }
    });

    test('lover 22-year-old differs from colleague 22-year-old', () {
      final lover = engine.suggestions(
        gender: 'nữ',
        age: 22,
        relationship: 'người yêu',
        name: 'Mai',
      );
      final colleague = engine.suggestions(
        gender: 'nữ',
        age: 22,
        relationship: 'đồng nghiệp',
        name: 'Mai',
      );
      // Item sets should differ (templates differ between banks).
      final loverNames = lover.map((e) => e.name).toSet();
      final colleagueNames = colleague.map((e) => e.name).toSet();
      expect(loverNames.difference(colleagueNames).isNotEmpty, isTrue);
    });
  });
}
