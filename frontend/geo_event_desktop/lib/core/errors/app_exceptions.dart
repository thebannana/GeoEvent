import 'package:dio/dio.dart';

import '../constants/app_strings.dart';

enum AppExceptionType {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  validation,
  conflict,
  server,
  cancelled,
  parsing,
  cache,
  unknown,
}

class AppException implements Exception {
  final AppExceptionType type;
  final String message;
  final int? statusCode;
  final Object? error;
  final StackTrace? stackTrace;

  const AppException({
    required this.type,
    required this.message,
    this.statusCode,
    this.error,
    this.stackTrace,
  });

  factory AppException.from(Object error, {StackTrace? stackTrace}) {
    if (error is AppException) {
      return error;
    }

    if (error is DioException) {
      return _fromDioException(error, stackTrace: stackTrace);
    }

    if (error is FormatException) {
      return AppException(
        type: AppExceptionType.parsing,
        message: _normalizeMessage(error.message, AppStrings.parsingError),
        error: error,
        stackTrace: stackTrace,
      );
    }

    return AppException(
      type: AppExceptionType.unknown,
      message: _normalizeMessage(error.toString(), AppStrings.genericError),
      error: error,
      stackTrace: stackTrace,
    );
  }

  static AppException _fromDioException(
    DioException exception, {
    StackTrace? stackTrace,
  }) {
    final statusCode = exception.response?.statusCode;
    final extractedMessage = _extractMessageFromResponse(exception.response?.data);

    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return AppException(
          type: AppExceptionType.timeout,
          message: extractedMessage ?? AppStrings.timeoutError,
          statusCode: statusCode,
          error: exception,
          stackTrace: stackTrace,
        );

      case DioExceptionType.badCertificate:
      case DioExceptionType.connectionError:
        return AppException(
          type: AppExceptionType.network,
          message: extractedMessage ?? AppStrings.networkError,
          statusCode: statusCode,
          error: exception,
          stackTrace: stackTrace,
        );

      case DioExceptionType.cancel:
        return AppException(
          type: AppExceptionType.cancelled,
          message: extractedMessage ?? AppStrings.cancelledError,
          statusCode: statusCode,
          error: exception,
          stackTrace: stackTrace,
        );

      case DioExceptionType.badResponse:
        return _fromStatusCode(
          statusCode,
          message: extractedMessage,
          error: exception,
          stackTrace: stackTrace,
        );

      case DioExceptionType.unknown:
        return AppException(
          type: AppExceptionType.unknown,
          message: extractedMessage ??
              _normalizeMessage(exception.message ?? '', AppStrings.genericError),
          statusCode: statusCode,
          error: exception,
          stackTrace: stackTrace,
        );
    }
  }

  static AppException _fromStatusCode(
    int? statusCode, {
    String? message,
    Object? error,
    StackTrace? stackTrace,
  }) {
    switch (statusCode) {
      case 400:
      case 422:
        return AppException(
          type: AppExceptionType.validation,
          message: message ?? AppStrings.validationError,
          statusCode: statusCode,
          error: error,
          stackTrace: stackTrace,
        );
      case 401:
        return AppException(
          type: AppExceptionType.unauthorized,
          message: message ?? AppStrings.unauthorized,
          statusCode: statusCode,
          error: error,
          stackTrace: stackTrace,
        );
      case 403:
        return AppException(
          type: AppExceptionType.forbidden,
          message: message ?? AppStrings.forbidden,
          statusCode: statusCode,
          error: error,
          stackTrace: stackTrace,
        );
      case 404:
        return AppException(
          type: AppExceptionType.notFound,
          message: message ?? AppStrings.notFoundError,
          statusCode: statusCode,
          error: error,
          stackTrace: stackTrace,
        );
        case 405:
          return AppException(
            type: AppExceptionType.validation,
            message: message ?? 'This action is not supported by the server.',
            statusCode: statusCode,
            error: error,
            stackTrace: stackTrace,
          );
      case 409:
        return AppException(
          type: AppExceptionType.conflict,
          message: message ?? AppStrings.conflictError,
          statusCode: statusCode,
          error: error,
          stackTrace: stackTrace,
        );
      case 500:
      case 502:
      case 503:
      case 504:
        return AppException(
          type: AppExceptionType.server,
          message: message ?? AppStrings.serverError,
          statusCode: statusCode,
          error: error,
          stackTrace: stackTrace,
        );
      default:
        return AppException(
          type: AppExceptionType.unknown,
          message: message ?? AppStrings.genericError,
          statusCode: statusCode,
          error: error,
          stackTrace: stackTrace,
        );
    }
  }

  static String? _extractMessageFromResponse(dynamic data) {
    if (data == null) return null;

    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    if (data is Map<String, dynamic>) {
      final candidates = [
        data['message'],
        data['error'],
        data['title'],
        data['detail'],
      ];

      for (final candidate in candidates) {
        if (candidate is String && candidate.trim().isNotEmpty) {
          return candidate.trim();
        }
      }

      final errors = data['errors'];
      if (errors is Map) {
        final messages = <String>[];

        for (final value in errors.values) {
          if (value is List) {
            for (final item in value) {
              if (item is String && item.trim().isNotEmpty) {
                messages.add(item.trim());
              }
            }
          } else if (value is String && value.trim().isNotEmpty) {
            messages.add(value.trim());
          }
        }

        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      }
    }

    return null;
  }

  static String _normalizeMessage(String raw, String fallback) {
    final text = raw.trim();

    if (text.isEmpty || text == 'Exception') {
      return fallback;
    }

    if (text.startsWith('Exception: ')) {
      final cleaned = text.replaceFirst('Exception: ', '').trim();
      return cleaned.isEmpty ? fallback : cleaned;
    }

    return text;
  }

  @override
  String toString() {
    return 'AppException(type: $type, message: $message, statusCode: $statusCode)';
  }
}