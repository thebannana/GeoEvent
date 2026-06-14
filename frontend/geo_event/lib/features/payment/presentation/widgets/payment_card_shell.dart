import 'package:flutter/material.dart';

class PaymentCardShell extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const PaymentCardShell({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.75),
        ),
      ),
      child: child,
    );
  }
}