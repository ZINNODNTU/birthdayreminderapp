import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;

/// Cloud payload for a single birthday photo. Immutable.
class EncodedBirthdayPhoto {
  const EncodedBirthdayPhoto({
    required this.base64,
    required this.mimeType,
    required this.byteSize,
    required this.hash,
  });

  /// Standard Base64 (no `data:` prefix).
  final String base64;

  /// MIME type — currently always `image/jpeg` after compression.
  final String mimeType;

  /// Compressed byte count (decoded from [base64]).
  final int byteSize;

  /// SHA-256 of the compressed bytes (NOT of the Base64 string).
  /// Lets us skip rewriting local files when nothing changed.
  final String hash;

  @override
  String toString() =>
      'EncodedBirthdayPhoto(mime=$mimeType, bytes=$byteSize, '
      'hash=${hash.substring(0, 8)}...)';
}

/// Result of an encode attempt. Use [failure] to surface a UI message
/// when the input is unusable.
class EncodePhotoResult {
  const EncodePhotoResult._({this.photo, this.failure});
  const EncodePhotoResult.success(EncodedBirthdayPhoto photo)
    : this._(photo: photo);
  const EncodePhotoResult.failure(String message) : this._(failure: message);

  final EncodedBirthdayPhoto? photo;
  final String? failure;

  bool get ok => photo != null;
}

/// Photo utility used by both the controller (before persisting
/// locally) and the sync layer (before pushing to Firestore).
///
/// Responsibilities:
///   * Decode + re-encode (resize to [maxDimension] longest side, JPEG
///     [quality]) so the stored payload is bounded.
///   * Reject sources that would still exceed [maxCompressedBytes]
///     after compression.
///   * Compute a SHA-256 hash for change detection.
///
/// Pure-Dart; only depends on `dart:convert`, `package:image` and
/// `package:crypto`.
class BirthdayPhotoService {
  const BirthdayPhotoService();

  /// Hard limit for the compressed byte payload. 600 KB leaves
  /// roughly 400 KB headroom for the rest of the Firestore document.
  static const int maxCompressedBytes = 600 * 1024;

  /// Longest-side cap for the JPEG re-encode.
  static const int maxDimension = 768;

  /// JPEG quality used by the re-encode.
  static const int jpegQuality = 78;

  /// Take a Base64 JPEG (the format `image_picker` produces) and
  /// return a compressed, hashed payload ready for Firestore.
  ///
  /// Returns a [EncodePhotoResult.failure] when:
  ///   * the input does not decode to a valid image
  ///   * the re-encoded bytes still exceed [maxCompressedBytes]
  ///
  /// Pure function — does not touch disk.
  Future<EncodePhotoResult> encodeForCloud({
    required String base64Input,
  }) async {
    Uint8List raw;
    try {
      raw = base64Decode(base64Input);
    } catch (_) {
      return const EncodePhotoResult.failure('invalid_base64');
    }
    img.Image? decoded;
    try {
      decoded = img.decodeImage(raw);
    } catch (_) {
      decoded = null;
    }
    if (decoded == null) {
      return const EncodePhotoResult.failure('invalid_image');
    }

    final resized = _resize(decoded, maxDimension);
    final compressed = img.encodeJpg(resized, quality: jpegQuality);

    if (compressed.length > maxCompressedBytes) {
      return EncodePhotoResult.failure('too_large:${compressed.length}');
    }

    final hash = sha256.convert(compressed).toString();
    return EncodePhotoResult.success(
      EncodedBirthdayPhoto(
        base64: base64Encode(compressed),
        mimeType: 'image/jpeg',
        byteSize: compressed.length,
        hash: hash,
      ),
    );
  }

  /// Inverse of [encodeForCloud] — for tests and for migrations that
  /// need to confirm the Base64 decodes back to a valid image.
  Uint8List? decodeFromCloud({required String base64Input}) {
    try {
      final bytes = base64Decode(base64Input);
      if (img.decodeImage(bytes) == null) return null;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  img.Image _resize(img.Image src, int maxSide) {
    final w = src.width;
    final h = src.height;
    if (w <= maxSide && h <= maxSide) return src;
    if (w >= h) {
      return img.copyResize(src, width: maxSide);
    }
    return img.copyResize(src, height: maxSide);
  }
}
