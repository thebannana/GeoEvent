import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_metrics.dart';

class AuthFormCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final BoxConstraints? constraints;

  const AuthFormCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppThemeMetrics.spaceLg),
    this.borderRadius = AppThemeMetrics.radiusXl + 2,
    this.constraints = const BoxConstraints(maxWidth: 560),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: constraints ?? const BoxConstraints(),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          shadowColor: Colors.transparent,
          color: theme.cardTheme.color ?? scheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}