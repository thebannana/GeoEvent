import 'package:flutter/material.dart';

class AppLoadingSheet extends StatelessWidget {
  final String title;
  final String? message;
  final EdgeInsetsGeometry padding;
  final bool centered;
  final Widget? leading;

  const AppLoadingSheet({
    super.key,
    this.title = 'Loading',
    this.message,
    this.padding = const EdgeInsets.all(24),
    this.centered = true,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final content = Padding(
      padding: padding,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.cardColor.withValues(alpha: 0.76),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.45),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                leading ??
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.hourglass_top_rounded,
                        color: colorScheme.primary,
                        size: 28,
                      ),
                    ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (message != null && message!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 18),
                LinearProgressIndicator(
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(999),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return centered ? Center(child: content) : content;
  }
}