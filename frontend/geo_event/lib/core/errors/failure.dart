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

  bool get isClientFailure =>
      type == FailureType.validation ||
      type == FailureType.conflict ||
      type == FailureType.notFound ||
      type == FailureType.forbidden;

  factory Failure.network({
    String message = 'No internet connection.',
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return Failure(
      type: FailureType.network,
      message: message,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  factory Failure.timeout({
    String message = 'The request timed out.',
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return Failure(
      type: FailureType.timeout,
      message: message,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  factory Failure.unauthorized({
    String message = 'You need to sign in again.',
    int? statusCode,
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return Failure(
      type: FailureType.unauthorized,
      message: message,
      statusCode: statusCode,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  factory Failure.forbidden({
    String message = 'You do not have permission to perform this action.',
    int? statusCode,
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return Failure(
      type: FailureType.forbidden,
      message: message,
      statusCode: statusCode,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  factory Failure.notFound({
    String message = 'The requested resource was not found.',
    int? statusCode,
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return Failure(
      type: FailureType.notFound,
      message: message,
      statusCode: statusCode,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  factory Failure.validation({
    String message = 'Some fields are invalid.',
    int? statusCode,
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return Failure(
      type: FailureType.validation,
      message: message,
      statusCode: statusCode,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  factory Failure.conflict({
    String message = 'This action conflicts with existing data.',
    int? statusCode,
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return Failure(
      type: FailureType.conflict,
      message: message,
      statusCode: statusCode,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  factory Failure.server({
    String message = 'The server encountered an error.',
    int? statusCode,
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return Failure(
      type: FailureType.server,
      message: message,
      statusCode: statusCode,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  factory Failure.cancelled({
    String message = 'The request was cancelled.',
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return Failure(
      type: FailureType.cancelled,
      message: message,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  factory Failure.parsing({
    String message = 'Failed to process server response.',
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return Failure(
      type: FailureType.parsing,
      message: message,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  factory Failure.cache({
    String message = 'Failed to read local data.',
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return Failure(
      type: FailureType.cache,
      message: message,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  factory Failure.unknown({
    String message = 'Something went wrong.',
    int? statusCode,
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return Failure(
      type: FailureType.unknown,
      message: message,
      statusCode: statusCode,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

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