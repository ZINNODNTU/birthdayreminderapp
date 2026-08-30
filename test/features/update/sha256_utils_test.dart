import 'package:flutter_test/flutter_test.dart';
import 'package:birthdayreminderapp/features/update/utils/sha256_utils.dart';

void main() {
  group('Sha256Utils', () {
    test('hashString produces a 64-char uppercase hex', () {
      final hash = Sha256Utils.hashString('hello');
      expect(hash.length, 64);
      expect(RegExp(r'^[0-9A-F]+$').hasMatch(hash), isTrue);
    });

    test('hashString is deterministic', () {
      expect(Sha256Utils.hashString('abc'), Sha256Utils.hashString('abc'));
    });

    test('hashString of empty string matches known SHA256', () {
      // SHA256("") = e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
      expect(
        Sha256Utils.hashString(''),
        'E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855',
      );
    });
  });
}
