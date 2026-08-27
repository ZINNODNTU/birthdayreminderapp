import 'package:flutter/foundation.dart';

/// Single-shot app-level failure surfaced to UI in place of raw exceptions.
///
/// Existing feature-specific failures (e.g. `AuthFailure`) remain. This type
/// is the catch-all for everything else until each domain owns its own.
sealed class AppFailure implements Exception {
  const AppFailure(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';

  /// User-facing message. Same as [message] for now; specific subtypes can
  /// override later without changing call sites.
  String get userMessage => message;
}

class NetworkFailure extends AppFailure {
  const NetworkFailure([super.message = 'Không có kết nối mạng']);
}

class DatabaseFailure extends AppFailure {
  const DatabaseFailure([super.message = 'Lỗi cơ sở dữ liệu cục bộ']);
}

class UnknownFailure extends AppFailure {
  const UnknownFailure([super.message = 'Đã xảy ra lỗi, vui lòng thử lại']);

  factory UnknownFailure.from(Object error) {
    if (error is AppFailure) return UnknownFailure(error.message);
    if (kDebugMode) {
      return UnknownFailure(error.toString());
    }
    return const UnknownFailure();
  }
}
