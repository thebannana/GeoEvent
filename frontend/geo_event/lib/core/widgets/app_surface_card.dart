import 'package:flutter/material.dart';

class AppSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final BorderRadiusGeometry borderRadius;
  final Color? color;
  final Color? borderColor;
  final Clip clipBehavior;

  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.color,
    this.borderColor,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final cardChild = Card(
      margin: margin ?? EdgeInsets.zero,
      color: color ?? theme.cardTheme.color,
      clipBehavior: clipBehavior,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(
          color: borderColor ?? theme.colorScheme.outline,
        ),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    if (onTap == null) return cardChild;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius.resolve(Directionality.of(context)),
        onTap: onTap,
        child: cardChild,
      ),
    );
  }
}