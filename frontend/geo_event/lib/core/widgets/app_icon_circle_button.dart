import 'package:flutter/material.dart';

class AppIconCircleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String tooltip;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;

  const AppIconCircleButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    this.size = 46,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor ?? theme.cardColor.withValues(alpha: 0.78),
        shape: CircleBorder(
          side: BorderSide(
            color: borderColor ??
                colorScheme.outline.withValues(alpha: 0.50),
          ),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              icon,
              size: 22,
              color: foregroundColor ?? colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}