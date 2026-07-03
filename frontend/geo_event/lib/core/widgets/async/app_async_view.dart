import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../feedback/app_empty_state.dart';
import '../feedback/app_error_state.dart';
import '../feedback/app_loading_indicator.dart';

class AppAsyncView<T> extends StatelessWidget {
  const AppAsyncView({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.errorBuilder,
    this.empty,
    this.isEmpty,
    this.onRetry,
    this.errorTitle = 'Something went wrong',
    this.emptyTitle,
    this.emptyMessage,
    this.loadingTitle = 'Loading',
    this.loadingMessage = 'Please wait while we prepare your content.',
    this.errorMessageBuilder,
    this.showRawErrorMessage = false,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget? loading;
  final Widget Function(Object error, StackTrace stackTrace)? errorBuilder;
  final Widget? empty;
  final bool Function(T value)? isEmpty;
  final VoidCallback? onRetry;
  final String errorTitle;
  final String? emptyTitle;
  final String? emptyMessage;
  final String loadingTitle;
  final String? loadingMessage;
  final String Function(Object error)? errorMessageBuilder;
  final bool showRawErrorMessage;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (result) {
        final shouldShowEmpty = isEmpty?.call(result) ?? false;
        if (shouldShowEmpty) {
          return empty ??
              AppEmptyState(
                title: emptyTitle ?? 'Nothing here yet',
                message: emptyMessage ?? 'There is no data to show right now.',
              );
        }

        return data(result);
      },
      loading: () {
        return loading ??
            AppLoadingIndicator(
              title: loadingTitle,
              message: loadingMessage,
            );
      },
      error: (error, stackTrace) {
        if (errorBuilder != null) {
          return errorBuilder!(error, stackTrace);
        }

        final message = errorMessageBuilder != null
            ? errorMessageBuilder!(error)
            : showRawErrorMessage
                ? error.toString()
                : 'An unexpected error occurred. Please try again.';

        return AppErrorState(
          title: errorTitle,
          message: message,
          onRetry: onRetry,
        );
      },
    );
  }
}