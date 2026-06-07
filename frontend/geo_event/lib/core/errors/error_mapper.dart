import 'package:dio/dio.dart';

import 'app_exception.dart';
import 'failure.dart';

class ErrorMapper {
  const ErrorMapper._();

  static AppException toAppException(
    Object error, {
    StackTrace? stackTrace,
  }) {
    if (error is AppException) {
      return error;
    }

    if (error is DioException) {
      return AppException.fromDioException(
        error,
        stackTrace: stackTrace,
      );
    }

    if (error is FormatException) {
      return AppException.parsing(
        message: error.message,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return AppException.unknown(
      message: _extractMessage(error),
      error: error,
      stackTrace: stackTrace,
    );
  }

  static Failure toFailure(
    Object error, {
    StackTrace? stackTrace,
  }) {
    final exception = toAppException(
      error,
      stackTrace: stackTrace,
    );
    return Failure.fromException(exception);
  }

  static String toMessage(
    Object error, {
    StackTrace? stackTrace,
    String fallbackMessage = 'Something went wrong.',
  }) {
    final failure = toFailure(
      error,
      stackTrace: stackTrace,
    );

    final message = failure.message.trim();
    if (message.isEmpty) return fallbackMessage;
    return message;
  }

  static String _extractMessage(Object error) {
    final text = error.toString().trim();

    if (text.isEmpty || text == 'Exception') {
      return 'Something went wrong.';
    }

    if (text.startsWith('Exception: ')) {
      return text.replaceFirst('Exception: ', '').trim();
    }

    return text;
  }
}