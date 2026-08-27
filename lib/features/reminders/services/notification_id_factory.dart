/// Pure, dependency-free 32-bit FNV-1a hash. Same input → same int,
/// across runs, devices and Dart versions. NOT a cryptographic hash
/// — its only job here is to spread keys uniformly into the 31-bit
/// non-negative integer space required by `flutter_local_notifications`.
///
/// Why FNV-1a and not `String.hashCode`?
///   * `String.hashCode` is not guaranteed stable across Dart versions
///     or runtimes.
///   * FNV-1a is a 12-line pure function we control.
class NotificationIdFactory {
  const NotificationIdFactory();

  /// Returns a non-negative 31-bit int derived from [key]. The high
  /// bit is masked off so the result is always >= 0 (Dart ints are
  /// 64-bit on the VM but platform channels serialize safely only
  /// for non-negative 31-bit ints).
  int idFor(String key) {
    // FNV-1a constants
    const int prime = 0x01000193;
    const int offsetBasis = 0x811C9DC5;
    const int mask31 = 0x7FFFFFFF;

    int hash = offsetBasis;
    for (final int codeUnit in key.codeUnits) {
      hash = (hash ^ codeUnit) & mask31;
      hash = (hash * prime) & mask31;
    }
    return hash;
  }

  /// Convenience for callers that want a fingerprint to detect
  /// "schedule changed" — any 32-bit deterministic int will do.
  int fingerprintFor(String key) => idFor('fp:$key');
}
