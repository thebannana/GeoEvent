import 'package:flutter/material.dart';

class AppIconCircleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? child;
  final String tooltip;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;

  const AppIconCircleButton({
    super.key,
    required this.onPressed,
    required this.tooltip,
    this.icon,
    this.child,
    this.size = 46,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
  }) : assert(icon != null || child != null);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor ?? colorScheme.surface,
        shape: CircleBorder(
          side: BorderSide(
            color: borderColor ?? colorScheme.outline,
          ),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: child ??
                  Icon(
                    icon,
                    size: 22,
                    color: foregroundColor ?? colorScheme.onSurface,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}