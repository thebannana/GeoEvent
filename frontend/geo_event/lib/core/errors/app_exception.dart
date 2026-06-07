import 'package:dio/dio.dart';

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

  factory AppException.network({
    String message = 'No internet connection.',
    Object? error,
    StackTrace? stackTrace,
  }) {
    return AppException(
      type: AppExceptionType.network,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  factory AppException.timeout({
    String message = 'The request timed out.',
    Object? error,
    StackTrace? stackTrace,
  }) {
    return AppException(
      type: AppExceptionType.timeout,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  factory AppException.unauthorized({
    String message = 'You need to sign in again.',
    int? statusCode,
    Object? error,
    StackTrace? stackTrace,
  }) {
    return AppException(
      type: AppExceptionType.unauthorized,
      message: message,
      statusCode: statusCode,
      error: error,
      stackTrace: stackTrace,
    );
  }

  factory AppException.forbidden({
    String message = 'You do not have permission to perform this action.',
    int? statusCode,
    Object? error,
    StackTrace? stackTrace,
  }) {
    return AppException(
      type: AppExceptionType.forbidden,
      message: message,
      statusCode: statusCode,
      error: error,
      stackTrace: stackTrace,
    );
  }

  factory AppException.notFound({
    String message = 'The requested resource was not found.',
    int? statusCode,
    Object? error,
    StackTrace? stackTrace,
  }) {
    return AppException(
      type: AppExceptionType.notFound,
      message: message,
      statusCode: statusCode,
      error: error,
      stackTrace: stackTrace,
    );
  }

  factory AppException.validation({
    String message = 'Some fields are invalid.',
    int? statusCode,
    Object? error,
    StackTrace? stackTrace,
  }) {
    return AppException(
      type: AppExceptionType.validation,
      message: message,
      statusCode: statusCode,
      error: error,
      stackTrace: stackTrace,
    );
  }

  factory AppException.conflict({
    String message = 'This action conflicts with existing data.',
    int? statusCode,
    Object? error,
    StackTrace? stackTrace,
  }) {
    return AppException(
      type: AppExceptionType.conflict,
      message: message,
      statusCode: statusCode,
      error: error,
      stackTrace: stackTrace,
    );
  }

  factory AppException.server({
    String message = 'The server encountered an error.',
    int? statusCode,
    Object? error,
    StackTrace? stackTrace,
  }) {
    return AppException(
      type: AppExceptionType.server,
      message: message,
      statusCode: statusCode,
      error: error,
      stackTrace: stackTrace,
    );
  }

  factory AppException.cancelled({
    String message = 'The request was cancelled.',
    Object? error,
    StackTrace? stackTrace,
  }) {
    return AppException(
      type: AppExceptionType.cancelled,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  factory AppException.parsing({
    String message = 'Failed to process server response.',
    Object? error,
    StackTrace? stackTrace,
  }) {
    return AppException(
      type: AppExceptionType.parsing,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  factory AppException.cache({
    String message = 'Failed to read local data.',
    Object? error,
    StackTrace? stackTrace,
  }) {
    return AppException(
      type: AppExceptionType.cache,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  factory AppException.unknown({
    String message = 'Something went wrong.',
    int? statusCode,
    Object? error,
    StackTrace? stackTrace,
  }) {
    return AppException(
      type: AppExceptionType.unknown,
      message: message,
      statusCode: statusCode,
      error: error,
      stackTrace: stackTrace,
    );
  }

  factory AppException.fromDioException(
    DioException exception, {
    StackTrace? stackTrace,
  }) {
    final statusCode = exception.response?.statusCode;
    final responseData = exception.response?.data;
    final extractedMessage = _extractMessageFromResponse(responseData);

    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppException.timeout(
          message: extractedMessage ?? 'The request timed out.',
          error: exception,
          stackTrace: stackTrace,
        );

      case DioExceptionType.badCertificate:
      case DioExceptionType.connectionError:
        return AppException.network(
          message: extractedMessage ?? 'Unable to connect to the server.',
          error: exception,
          stackTrace: stackTrace,
        );

      case DioExceptionType.cancel:
        return AppException.cancelled(
          message: extractedMessage ?? 'The request was cancelled.',
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
        return AppException.unknown(
          message: extractedMessage ?? 'An unexpected network error occurred.',
          error: exception,
          stackTrace: stackTrace,
        );
    }
  }

  static AppException from(
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
      message: error.toString(),
      error: error,
      stackTrace: stackTrace,
    );
  }

  static AppException _fromStatusCode(
    int? statusCode, {
    String? message,
    Object? error,
    StackTrace? stackTrace,
  }) {
    switch (statusCode) {
      case 400:
        return AppException.validation(
          message: message ?? 'Invalid request.',
          statusCode: statusCode,
          error: error,
          stackTrace: stackTrace,
        );
      case 401:
        return AppException.unauthorized(
          message: message ?? 'You need to sign in again.',
          statusCode: statusCode,
          error: error,
          stackTrace: stackTrace,
        );
      case 403:
        return AppException.forbidden(
          message: message ?? 'You do not have permission to perform this action.',
          statusCode: statusCode,
          error: error,
          stackTrace: stackTrace,
        );
      case 404:
        return AppException.notFound(
          message: message ?? 'The requested resource was not found.',
          statusCode: statusCode,
          error: error,
          stackTrace: stackTrace,
        );
      case 409:
        return AppException.conflict(
          message: message ?? 'This action conflicts with existing data.',
          statusCode: statusCode,
          error: error,
          stackTrace: stackTrace,
        );
      case 422:
        return AppException.validation(
          message: message ?? 'Some fields are invalid.',
          statusCode: statusCode,
          error: error,
          stackTrace: stackTrace,
        );
      case 500:
      case 502:
      case 503:
      case 504:
        return AppException.server(
          message: message ?? 'The server encountered an error.',
          statusCode: statusCode,
          error: error,
          stackTrace: stackTrace,
        );
      default:
        return AppException.unknown(
          message: message ?? 'Something went wrong.',
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
      if (errors is Map<String, dynamic>) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) {
            final first = value.first;
            if (first is String && first.trim().isNotEmpty) {
              return first.trim();
            }
          }

          if (value is String && value.trim().isNotEmpty) {
            return value.trim();
          }
        }
      }
    }

    return null;
  }

  @override
  String toString() {
    return 'AppException(type: $type, message: $message, statusCode: $statusCode)';
  }
}