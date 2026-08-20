import 'package:flutter/foundation.dart';

enum AppLogLevel {
  debug,
  info,
  warning,
  error,
}

class AppLogger {
  const AppLogger._();

  static void debug(
    String message, {
    String? tag,
  }) {
    _write(
      AppLogLevel.debug,
      message,
      tag: tag,
    );
  }

  static void info(
    String message, {
    String? tag,
  }) {
    _write(
      AppLogLevel.info,
      message,
      tag: tag,
    );
  }

  static void warning(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _write(
      AppLogLevel.warning,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _write(
      AppLogLevel.error,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void _write(
    AppLogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode && level != AppLogLevel.error) {
      return;
    }

    final normalizedTag = tag?.trim();
    final prefix = normalizedTag == null || normalizedTag.isEmpty
        ? '[${level.name.toUpperCase()}]'
        : '[${level.name.toUpperCase()}][$normalizedTag]';

    debugPrint('$prefix $message');

    if (error != null) {
      debugPrint('$prefix Cause: $error');
    }

    if (stackTrace != null && kDebugMode) {
      debugPrintStack(
        stackTrace: stackTrace,
        label: '$prefix Stack trace',
      );
    }

  }
}