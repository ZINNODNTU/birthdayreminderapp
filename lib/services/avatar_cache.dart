import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Bounded in‑memory cache for decoded avatar images.
/// Keys are SHA‑256 of the Base64 payload; eviction is LRU.
class AvatarCache {
  static const int maxSize = 30;
  static final Map<String, Uint8List> _cache = {};
  static final List<String> _keys = [];

  static Uint8List? get(String key) => _cache[key];

  static void put(String key, Uint8List bytes) {
    if (_cache.containsKey(key)) {
      _keys.remove(key);
      _keys.add(key);
      return;
    }
    if (_keys.length >= maxSize) {
      final oldest = _keys.removeAt(0);
      _cache.remove(oldest);
    }
    _cache[key] = bytes;
    _keys.add(key);
  }

  /// Decodes the Base64 string if not already cached, stores it, and returns
  /// the decoded bytes. Returns `null` on decode failure or empty input.
  static Uint8List? decodeAndCache(String base64) {
    if (base64.isEmpty) return null;
    final key = sha256.convert(utf8.encode(base64)).toString();
    final cached = get(key);
    if (cached != null) return cached;
    try {
      final bytes = base64Decode(base64);
      put(key, bytes);
      return bytes;
    } catch (_) {
      return null;
    }
  }

  /// Clear the entire cache – used in tests and after avatar changes.
  static void clear() {
    _cache.clear();
    _keys.clear();
  }
}
