import 'app_exception.dart';

enum FailureType {
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

class Failure {
  final FailureType type;
  final String message;
  final int? statusCode;
  final Object? cause;
  final StackTrace? stackTrace;

  const Failure({
    required this.type,
    required this.message,
    this.statusCode,
    this.cause,
    this.stackTrace,
  });

  bool get isNetworkFailure =>
      type == FailureType.network || type == FailureType.timeout;

  bool get isAuthFailure =>
      type == FailureType.unauthorized || type == FailureType.forbidden;

  bool get isValidationFailure => type == FailureType.validation;
  bool get isServerFailure => type == FailureType.server;
  bool get isNotFoundFailure => type == FailureType.notFound;
  bool get isCancelled => type == FailureType.cancelled;

  bool get isRetryable =>
      type == FailureType.network ||
      type == FailureType.timeout ||
      type == FailureType.server;

  factory Failure.fromException(AppException exception) {
    return Failure(
      type: _mapExceptionType(exception.type),
      message: exception.message,
      statusCode: exception.statusCode,
      cause: exception.error,
      stackTrace: exception.stackTrace,
    );
  }

  static FailureType _mapExceptionType(AppExceptionType type) {
    switch (type) {
      case AppExceptionType.network:
        return FailureType.network;
      case AppExceptionType.timeout:
        return FailureType.timeout;
      case AppExceptionType.unauthorized:
        return FailureType.unauthorized;
      case AppExceptionType.forbidden:
        return FailureType.forbidden;
      case AppExceptionType.notFound:
        return FailureType.notFound;
      case AppExceptionType.validation:
        return FailureType.validation;
      case AppExceptionType.conflict:
        return FailureType.conflict;
      case AppExceptionType.server:
        return FailureType.server;
      case AppExceptionType.cancelled:
        return FailureType.cancelled;
      case AppExceptionType.parsing:
        return FailureType.parsing;
      case AppExceptionType.cache:
        return FailureType.cache;
      case AppExceptionType.unknown:
        return FailureType.unknown;
    }
  }

  @override
  String toString() {
    return 'Failure(type: $type, message: $message, statusCode: $statusCode)';
  }
}