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
    switch (exception.type) {
      case AppExceptionType.network:
        return Failure.network(
          message: exception.message,
          cause: exception.error,
          stackTrace: exception.stackTrace,
        );
      case AppExceptionType.timeout:
        return Failure.timeout(
          message: exception.message,
          cause: exception.error,
          stackTrace: exception.stackTrace,
        );
      case AppExceptionType.unauthorized:
        return Failure.unauthorized(
          message: exception.message,
          statusCode: exception.statusCode,
          cause: exception.error,
          stackTrace: exception.stackTrace,
        );
      case AppExceptionType.forbidden:
        return Failure.forbidden(
          message: exception.message,
          statusCode: exception.statusCode,
          cause: exception.error,
          stackTrace: exception.stackTrace,
        );
      case AppExceptionType.notFound:
        return Failure.notFound(
          message: exception.message,
          statusCode: exception.statusCode,
          cause: exception.error,
          stackTrace: exception.stackTrace,
        );
      case AppExceptionType.validation:
        return Failure.validation(
          message: exception.message,
          statusCode: exception.statusCode,
          cause: exception.error,
          stackTrace: exception.stackTrace,
        );
      case AppExceptionType.conflict:
        return Failure.conflict(
          message: exception.message,
          statusCode: exception.statusCode,
          cause: exception.error,
          stackTrace: exception.stackTrace,
        );
      case AppExceptionType.server:
        return Failure.server(
          message: exception.message,
          statusCode: exception.statusCode,
          cause: exception.error,
          stackTrace: exception.stackTrace,
        );
      case AppExceptionType.cancelled:
        return Failure.cancelled(
          message: exception.message,
          cause: exception.error,
          stackTrace: exception.stackTrace,
        );
      case AppExceptionType.parsing:
        return Failure.parsing(
          message: exception.message,
          cause: exception.error,
          stackTrace: exception.stackTrace,
        );
      case AppExceptionType.cache:
        return Failure.cache(
          message: exception.message,
          cause: exception.error,
          stackTrace: exception.stackTrace,
        );
      case AppExceptionType.unknown:
        return Failure.unknown(
          message: exception.message,
          statusCode: exception.statusCode,
          cause: exception.error,
          stackTrace: exception.stackTrace,
        );
    }
  }

  @override
  String toString() {
    return 'Failure(type: $type, message: $message, statusCode: $statusCode)';
  }
}