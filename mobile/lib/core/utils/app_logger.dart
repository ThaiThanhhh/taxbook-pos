import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Thay cho `print` (bị cấm bởi lint `avoid_print`). Chỉ ghi log ở debug.
abstract final class AppLogger {
  static void d(String message, {String tag = 'DT13'}) {
    if (kDebugMode) developer.log(message, name: tag);
  }

  static void e(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String tag = 'DT13',
  }) {
    if (kDebugMode) {
      developer.log(
        message,
        name: tag,
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }
}
