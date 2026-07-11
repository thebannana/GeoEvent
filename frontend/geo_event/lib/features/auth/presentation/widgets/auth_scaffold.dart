import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_metrics.dart';
import '../../../../core/widgets/layout/app_scaffold.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.child,
    this.padding,
    this.showBackButton = true,
  });

  final String title;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final canPop = context.canPop();

    return AppScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: showBackButton && canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Back',
                onPressed: () => context.pop(),
              )
            : null,
        title: Text(title),
      ),
      child: SafeArea(
        child: ListView(
          padding: padding ?? const EdgeInsets.all(AppThemeMetrics.spaceXl),
          children: [child],
        ),
      ),
    );
  }
}