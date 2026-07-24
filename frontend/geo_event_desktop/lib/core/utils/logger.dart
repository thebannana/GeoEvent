import 'package:flutter/foundation.dart';

class AppLogger {
  const AppLogger._();

  static void debug(
    String message, {
    String? tag,
  }) {
    _print('DEBUG', message, tag: tag);
  }

  static void info(
    String message, {
    String? tag,
  }) {
    _print('INFO', message, tag: tag);
  }

  static void warning(
    String message, {
    String? tag,
  }) {
    _print('WARN', message, tag: tag);
  }

  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _print('ERROR', message, tag: tag);

    if (error != null) {
      _print('ERROR', 'Cause: $error', tag: tag);
    }

    if (stackTrace != null && kDebugMode) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static void _print(
    String level,
    String message, {
    String? tag,
  }) {
    if (!kDebugMode) return;

    final prefix = tag == null || tag.isEmpty
        ? '[$level]'
        : '[$level][$tag]';

    debugPrint('$prefix $message', wrapWidth: 1024);
  }
}