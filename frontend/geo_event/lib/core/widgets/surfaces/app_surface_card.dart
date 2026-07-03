import 'package:flutter/material.dart';

import '../../theme/app_theme_metrics.dart';

class AppSurfaceCard extends StatelessWidget {
  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppThemeMetrics.spaceMd),
    this.margin,
    this.onTap,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(AppThemeMetrics.radiusXl),
    ),
    this.color,
    this.borderColor,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final BorderRadiusGeometry borderRadius;
  final Color? color;
  final Color? borderColor;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: margin ?? EdgeInsets.zero,
      color: color ?? theme.cardTheme.color,
      clipBehavior: clipBehavior,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(
          color: borderColor ?? theme.colorScheme.outline,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius.resolve(Directionality.of(context)),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}