import 'package:flutter/foundation.dart';

/// Centralized logger for the application.
/// Avoids silent error swallowing and provides uniform log messages.
class AppLogger {
  AppLogger._();

  static void debug(String message) {
    if (kDebugMode) {
      debugPrint('[DEBUG] $message');
    }
  }

  static void info(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] $message');
    }
  }

  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[WARN] $message${error != null ? ' | Error: $error' : ''}');
      if (stackTrace != null) {
        debugPrint(stackTrace.toString());
      }
    }
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message${error != null ? ' | Error: $error' : ''}');
      if (stackTrace != null) {
        debugPrint(stackTrace.toString());
      }
    }
  }
}
