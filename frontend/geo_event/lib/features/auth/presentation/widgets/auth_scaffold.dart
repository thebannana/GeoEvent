import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_metrics.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: showBackButton,
        title: Text(title),
      ),
      body: SafeArea(
        child: ListView(
          padding:
              padding ?? const EdgeInsets.all(AppThemeMetrics.spaceXl),
          children: [child],
        ),
      ),
    );
  }
}