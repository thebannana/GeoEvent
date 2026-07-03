import 'package:flutter/material.dart';

import '../../../../core/errors/error_mapper.dart';

mixin AuthFeedback {
  void showAuthError(
    BuildContext context,
    Object error, {
    StackTrace? stackTrace,
    required String fallbackMessage,
  }) {
    final message = ErrorMapper.toMessage(
      error,
      stackTrace: stackTrace,
      fallbackMessage: fallbackMessage,
    );

    showAuthMessage(context, message);
  }

  void showAuthErrorMessage(BuildContext context, String message) {
    showAuthMessage(context, message);
  }

  void showAuthSuccess(BuildContext context, String message) {
    showAuthMessage(context, message);
  }

  void showAuthMessage(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }
}