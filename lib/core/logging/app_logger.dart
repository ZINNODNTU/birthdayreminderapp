import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Centralised logger. Debug builds print full detail; release builds only
/// emit a sanitised summary to platform log.
///
/// The logger intentionally has no reference to a logger backend so it can
/// stay dependency-free.
class AppLogger {
  const AppLogger._();

  static void debug(String tag, String message) {
    if (!kDebugMode) return;
    developer.log('$tag | $message', name: 'birthdayreminderapp');
  }

  static void info(String tag, String message) {
    developer.log('$tag | $message', name: 'birthdayreminderapp');
  }

  static void warn(String tag, String message) {
    developer.log(
      '$tag | WARN | $message',
      name: 'birthdayreminderapp',
      level: 900,
    );
  }

  static void error(String tag, Object error, [StackTrace? stack]) {
    if (kDebugMode) {
      developer.log(
        '$tag | ERROR | $error',
        name: 'birthdayreminderapp',
        error: error,
        stackTrace: stack,
        level: 1000,
      );
    } else {
      // Release: never log full error / stack; only a hint.
      developer.log(
        '$tag | ERROR | ${error.runtimeType}',
        name: 'birthdayreminderapp',
        level: 1000,
      );
    }
  }
}
