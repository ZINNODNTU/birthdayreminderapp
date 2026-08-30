import 'package:birthdayreminderapp/features/backup/services/backup_file_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackupFileService.normalizeBase64', () {
    test('passes through plain base64', () {
      const raw = 'aGVsbG8=';
      expect(BackupFileService.normalizeBase64(raw), raw);
    });

    test('strips data URL prefix with mime', () {
      const raw = 'data:image/jpeg;base64,aGVsbG8=';
      expect(BackupFileService.normalizeBase64(raw), 'aGVsbG8=');
    });

    test('drops whitespace and trims', () {
      const raw = '   data:image/png;base64,aGVs\nbG8=\n  ';
      expect(BackupFileService.normalizeBase64(raw), 'aGVsbG8=');
    });

    test('rejects non-base64 garbage', () {
      expect(BackupFileService.normalizeBase64('not-base64!'), isNull);
    });
  });
}
