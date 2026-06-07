import 'package:flutter/material.dart';

class AppErrorView extends StatelessWidget {
  final String title;
  final String? message;
  final String retryLabel;
  final VoidCallback? onRetry;
  final IconData icon;
  final EdgeInsetsGeometry padding;

  const AppErrorView({
    super.key,
    this.title = 'Something went wrong',
    this.message,
    this.retryLabel = 'Try again',
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: padding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: colorScheme.error,
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (message != null && message!.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: onRetry,
                  child: Text(retryLabel),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}