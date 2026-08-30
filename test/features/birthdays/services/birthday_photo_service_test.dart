import 'dart:convert';
import 'dart:typed_data';

import 'package:birthdayreminderapp/features/birthdays/services/birthday_photo_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

Uint8List _makeJpegBytes({
  required int width,
  required int height,
  int quality = 90,
}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(200, 30, 30));
  return Uint8List.fromList(img.encodeJpg(image, quality: quality));
}

void main() {
  group('BirthdayPhotoService', () {
    const service = BirthdayPhotoService();

    test('rejects non-base64 input', () async {
      final result = await service.encodeForCloud(base64Input: 'not-base64!@#');
      expect(result.ok, false);
      expect(result.failure, 'invalid_base64');
    });

    test('rejects base64 that does not decode to an image', () async {
      final result = await service.encodeForCloud(
        base64Input: base64Encode(List.filled(64, 0)),
      );
      expect(result.ok, false);
      expect(result.failure, 'invalid_image');
    });

    test('encodes a small JPEG and round-trips to valid JPEG bytes', () async {
      final bytes = _makeJpegBytes(width: 200, height: 150);
      final base64 = base64Encode(bytes);

      final result = await service.encodeForCloud(base64Input: base64);

      expect(result.ok, true);
      final photo = result.photo!;
      expect(photo.mimeType, 'image/jpeg');
      expect(photo.byteSize, greaterThan(0));
      expect(
        photo.byteSize,
        lessThanOrEqualTo(BirthdayPhotoService.maxCompressedBytes),
      );
      expect(photo.hash.length, 64); // SHA-256 hex

      final decoded = service.decodeFromCloud(base64Input: photo.base64);
      expect(decoded, isNotNull);
      expect(img.decodeImage(decoded!), isNotNull);
    });

    test('downsizes oversized images to fit the byte cap', () async {
      final huge = img.Image(width: 4000, height: 3000);
      for (final p in huge) {
        p
          ..r = (p.x * 7) & 0xFF
          ..g = (p.y * 13) & 0xFF
          ..b = ((p.x + p.y) * 5) & 0xFF;
      }
      final raw = Uint8List.fromList(img.encodeJpg(huge, quality: 95));
      final base64 = base64Encode(raw);

      final result = await service.encodeForCloud(base64Input: base64);

      expect(
        result.ok,
        true,
        reason: 'should still encode successfully (downsized)',
      );
      expect(
        result.photo!.byteSize,
        lessThanOrEqualTo(BirthdayPhotoService.maxCompressedBytes),
      );
    });

    test('decodeFromCloud returns null for garbage input', () {
      expect(service.decodeFromCloud(base64Input: '!!!'), isNull);
      expect(
        service.decodeFromCloud(base64Input: base64Encode([1, 2, 3])),
        isNull,
      );
    });
  });
}
