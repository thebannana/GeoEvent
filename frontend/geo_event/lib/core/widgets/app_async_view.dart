import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_empty_state.dart';
import 'app_error_view.dart';
import 'app_loading_sheet.dart';

class AppAsyncView<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget? loading;
  final Widget Function(Object error, StackTrace stackTrace)? errorBuilder;
  final Widget? empty;
  final bool Function(T value)? isEmpty;

  const AppAsyncView({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.errorBuilder,
    this.empty,
    this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (result) {
        final shouldShowEmpty = isEmpty?.call(result) ?? false;
        if (shouldShowEmpty) {
          return empty ??
              const AppEmptyState(
                title: 'Nothing here yet',
                message: 'There is no data to show right now.',
              );
        }

        return data(result);
      },
      loading: () {
        return loading ??
            const AppLoadingSheet(
              title: 'Loading',
              message: 'Please wait while we prepare your content.',
            );
      },
      error: (error, stackTrace) {
        if (errorBuilder != null) {
          return errorBuilder!(error, stackTrace);
        }

        return AppErrorView(
          message: error.toString(),
        );
      },
    );
  }
}