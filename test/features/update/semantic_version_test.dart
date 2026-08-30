import 'package:flutter_test/flutter_test.dart';
import 'package:birthdayreminderapp/features/update/utils/semantic_version.dart';

void main() {
  group('SemanticVersion.parse', () {
    test('parses standard 3-part version', () {
      final v = SemanticVersion.parse('1.2.3');
      expect(v, isNotNull);
      expect(v!.major, 1);
      expect(v.minor, 2);
      expect(v.patch, 3);
      expect(v.build, 0);
    });

    test('parses version with build', () {
      final v = SemanticVersion.parse('1.0.1+4');
      expect(v, isNotNull);
      expect(v!.major, 1);
      expect(v.minor, 0);
      expect(v.patch, 1);
      expect(v.build, 4);
    });

    test('returns null for invalid input', () {
      expect(SemanticVersion.parse('foo'), isNull);
      expect(SemanticVersion.parse('1.2'), isNull);
      expect(SemanticVersion.parse('1.2.x'), isNull);
      expect(SemanticVersion.parse(''), isNull);
    });
  });

  group('SemanticVersion comparison', () {
    test('1.0.1 > 1.0.0', () {
      expect(
        SemanticVersion.parse('1.0.1')! > SemanticVersion.parse('1.0.0')!,
        isTrue,
      );
    });

    test('1.1.0 > 1.0.9', () {
      expect(
        SemanticVersion.parse('1.1.0')! > SemanticVersion.parse('1.0.9')!,
        isTrue,
      );
    });

    test('1.10.0 > 1.9.9 (NOT lexicographic)', () {
      expect(
        SemanticVersion.parse('1.10.0')! > SemanticVersion.parse('1.9.9')!,
        isTrue,
      );
    });

    test('2.0.0 > 1.99.99', () {
      expect(
        SemanticVersion.parse('2.0.0')! > SemanticVersion.parse('1.99.99')!,
        isTrue,
      );
    });

    test('1.0.1+3 > 1.0.1+2', () {
      expect(
        SemanticVersion.parse('1.0.1+3')! > SemanticVersion.parse('1.0.1+2')!,
        isTrue,
      );
    });

    test('equal versions compare as equal', () {
      expect(
        SemanticVersion.parse(
          '1.2.3',
        )!.compareTo(SemanticVersion.parse('1.2.3')!),
        0,
      );
    });

    test('greater patch wins', () {
      expect(
        SemanticVersion.parse('1.2.4')! > SemanticVersion.parse('1.2.3')!,
        isTrue,
      );
    });

    test('greater minor wins', () {
      expect(
        SemanticVersion.parse('1.3.0')! > SemanticVersion.parse('1.2.99')!,
        isTrue,
      );
    });

    test('major wins over all', () {
      expect(
        SemanticVersion.parse('2.0.0')! > SemanticVersion.parse('1.999.999')!,
        isTrue,
      );
    });
  });

  test('toString formats with build when present', () {
    expect(SemanticVersion.parse('1.0.0')!.toString(), '1.0.0');
    expect(SemanticVersion.parse('1.0.0+3')!.toString(), '1.0.0+3');
  });
}
