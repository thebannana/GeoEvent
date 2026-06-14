import 'package:flutter/material.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final EdgeInsetsGeometry padding;
  final TextAlign textAlign;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
    this.padding = const EdgeInsets.only(bottom: 24),
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primaryContainer,
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Icon(
                icon,
                size: 32,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 18),
          ],
          Text(
            title,
            textAlign: textAlign,
            style: textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: textAlign,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}