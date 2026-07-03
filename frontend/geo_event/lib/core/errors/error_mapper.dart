import 'app_exception.dart';
import 'failure.dart';

class ErrorMapper {
  const ErrorMapper._();

  static AppException toAppException(
    Object error, {
    StackTrace? stackTrace,
  }) {
    return AppException.from(error, stackTrace: stackTrace);
  }

  static Failure toFailure(
    Object error, {
    StackTrace? stackTrace,
  }) {
    return Failure.fromException(
      toAppException(error, stackTrace: stackTrace),
    );
  }

  static String toMessage(
    Object error, {
    StackTrace? stackTrace,
    String fallbackMessage = 'Something went wrong.',
  }) {
    final message = toFailure(
      error,
      stackTrace: stackTrace,
    ).message.trim();

    return message.isEmpty ? fallbackMessage : message;
  }
}