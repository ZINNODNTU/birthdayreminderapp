import 'package:birthdayreminderapp/features/ai/services/ai_response_parsers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('looksLikeRawJson', () {
    test('flags leading JSON braces', () {
      expect(looksLikeRawJson('{"gifts":[]}'), isTrue);
      expect(looksLikeRawJson('[1,2,3]'), isTrue);
    });

    test('flags JSON-shaped markers inside', () {
      expect(looksLikeRawJson('boom "name":"foo" boom'), isTrue);
      expect(looksLikeRawJson('hello ```json\nfoo'), isTrue);
    });

    test('passes plain text', () {
      expect(looksLikeRawJson('Áo thun cotton'), isFalse);
      expect(looksLikeRawJson('Nước hoa'), isFalse);
      expect(looksLikeRawJson(''), isFalse);
    });
  });

  group('normalizeAiJson', () {
    test('strips BOM', () {
      final s = normalizeAiJson('\uFEFF{"gifts":[{"name":"A"}]}');
      expect(s.startsWith('{'), isTrue);
    });

    test('strips fences', () {
      final s = normalizeAiJson('```json\n{"gifts":[{"name":"A"}]}\n```');
      expect(s, '{"gifts":[{"name":"A"}]}');
    });

    test('drops leading prose', () {
      final s = normalizeAiJson('Đây là kết quả:\n{"gifts":[{"name":"A"}]}');
      expect(s.startsWith('{'), isTrue);
    });
  });

  group('recoverArrayChildren', () {
    test('handles truncated trailing object', () {
      final src =
          '{"gifts":['
          '{"name":"A","reason":"a"},'
          '{"name":"B","reason":"b"},'
          '{"name":"C"';
      final out = recoverArrayChildren(src, 'gifts');
      expect(out.length, 2);
      expect(out[0]['name'], 'A');
      expect(out[1]['name'], 'B');
    });

    test('returns [] when key absent', () {
      expect(recoverArrayChildren('hello world', 'gifts'), isEmpty);
    });
  });

  group('GiftSuggestionsParser (regression)', () {
    const parser = GiftSuggestionsParser();

    test('minified JSON one line -> 2 items, NEVER 1 raw item', () {
      const json = '{"gifts":[{"name":"A"},{"name":"B"}]}';
      final r = parser.parse(json);
      expect(r.items.length, 2);
      expect(r.items[0].name, 'A');
      expect(r.items[1].name, 'B');
      expect(looksLikeRawJson(r.items[0].name), isFalse);
    });

    test('valid 10 -> 10', () {
      final json =
          '{"gifts":[${List.generate(10, (i) => '{"name":"Q$i"}').join(',')}]}';
      expect(parser.parse(json).items.length, 10);
    });

    test('11 items -> cap 10', () {
      final json =
          '{"gifts":[${List.generate(11, (i) => '{"name":"Q$i"}').join(',')}]}';
      expect(parser.parse(json).items.length, 10);
    });

    test('truncated JSON -> recover only completed', () {
      const src =
          '{"gifts":['
          '{"name":"A"},'
          '{"name":"B"},'
          '{"name":"C"';
      final r = parser.parse(src);
      expect(r.items.length, 2);
      expect(r.items.map((e) => e.name).toList(), ['A', 'B']);
    });

    test('raw JSON never becomes a single item', () {
      const json = '{"gifts":[{"name":"X"}]}';
      final r = parser.parse(json);
      expect(r.items.length, 1);
      expect(r.items.first.name, 'X');
      // Must NOT be raw JSON
      expect(looksLikeRawJson(r.items.first.name), isFalse);
    });

    test('structured JSON that fails decode + looks like JSON -> empty', () {
      // Looks like JSON but no complete top-level `{...}` children are
      // recoverable — the trailing fragment is unterminated. The UI
      // must NOT fall through to the line-fallback that would render
      // the raw string as a single gift.
      const src = '{"gifts":[{"name":"A"';
      final r = parser.parse(src);
      expect(r.items, isEmpty);
      expect(r.items.any((e) => looksLikeRawJson(e.name)), isFalse);
    });

    test('plain text fallback is allowed and is parsed line-by-line', () {
      const src = 'Áo thun\nNước hoa\nTai nghe';
      final r = parser.parse(src);
      expect(r.items.length, 3);
      expect(r.items[0].name, 'Áo thun');
    });
  });

  group('BirthdayWishParser (regression)', () {
    const parser = BirthdayWishParser();

    test('minified JSON one line -> 2 items', () {
      const json =
          '{"wishes":[{"style":"A","text":"x"},{"style":"B","text":"y"}]}';
      final r = parser.parse(json);
      expect(r.wishes.length, 2);
      expect(r.wishes[0].text, 'x');
      expect(looksLikeRawJson(r.wishes[0].text), isFalse);
    });

    test('valid 10 -> 10', () {
      final json =
          '{"wishes":[${List.generate(10, (i) => '{"style":"S$i","text":"T$i"}').join(',')}]}';
      expect(parser.parse(json).wishes.length, 10);
    });

    test('11 items -> cap 10', () {
      final json =
          '{"wishes":[${List.generate(11, (i) => '{"style":"S$i","text":"T$i"}').join(',')}]}';
      expect(parser.parse(json).wishes.length, 10);
    });

    test('truncated JSON -> recover completed', () {
      const src =
          '{"wishes":['
          '{"style":"A","text":"x"},'
          '{"style":"B","text":"y"},'
          '{"style":"C","text":"z"';
      final r = parser.parse(src);
      expect(r.wishes.length, 2);
      expect(r.wishes[0].text, 'x');
      expect(r.wishes[1].text, 'y');
    });

    test('no valid items + looks like JSON -> empty (not raw)', () {
      const src = '{"wishes":[{"style":"A","text":"x"';
      final r = parser.parse(src);
      expect(r.wishes, isEmpty);
      expect(r.wishes.any((w) => looksLikeRawJson(w.text)), isFalse);
    });

    test('plain text fallback', () {
      const src = 'Chúc vui vẻ\nChúc hạnh phúc';
      final r = parser.parse(src);
      expect(r.wishes.length, 2);
      expect(r.wishes[0].text, 'Chúc vui vẻ');
    });
  });
}
