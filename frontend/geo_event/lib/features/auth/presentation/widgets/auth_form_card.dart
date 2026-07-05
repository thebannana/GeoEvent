import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_metrics.dart';
import '../../../../core/widgets/surfaces/app_surface_card.dart';

class AuthFormCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BoxConstraints? constraints;

  const AuthFormCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppThemeMetrics.spaceLg),
    this.constraints = const BoxConstraints(maxWidth: 560),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: constraints ?? const BoxConstraints(),
        child: AppSurfaceCard(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}