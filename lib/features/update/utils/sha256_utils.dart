import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// SHA-256 utility functions.
class Sha256Utils {
  /// Compute SHA-256 of a file.
  static Future<String> hashFile(File file) async {
    final bytes = await file.readAsBytes();
    return hashBytes(bytes);
  }

  /// Compute SHA-256 of bytes.
  static String hashBytes(Uint8List bytes) {
    return sha256.convert(bytes).toString().toUpperCase();
  }

  /// Compute SHA-256 of a string (UTF-8).
  static String hashString(String input) {
    return sha256.convert(utf8.encode(input)).toString().toUpperCase();
  }
}
