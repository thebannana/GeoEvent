import 'package:flutter/material.dart';

class AppChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;
  final IconData? icon;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;

  final Color? selectedBackgroundColor;
  final Color? selectedForegroundColor;
  final Color? selectedBorderColor;

  final double radius;
  final bool compact;

  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.enabled = true,
    this.onTap,
    this.icon,
    this.trailing,
    this.padding,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.selectedBackgroundColor,
    this.selectedForegroundColor,
    this.selectedBorderColor,
    this.radius = 999,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveSelected = selected;
    final effectiveEnabled = enabled && onTap != null;

    final defaultForeground =
        effectiveSelected ? colorScheme.primary : colorScheme.onSurface;

    final defaultBackground = effectiveSelected
        ? colorScheme.primary.withValues(alpha: 0.14)
        : colorScheme.surface.withValues(alpha: 0.82);

    final defaultBorder = effectiveSelected
        ? colorScheme.primary.withValues(alpha: 0.35)
        : colorScheme.outline.withValues(alpha: 0.65);

    final resolvedForeground = effectiveSelected
        ? (selectedForegroundColor ?? foregroundColor ?? defaultForeground)
        : (foregroundColor ?? defaultForeground);

    final resolvedBackground = effectiveSelected
        ? (selectedBackgroundColor ?? backgroundColor ?? defaultBackground)
        : (backgroundColor ?? defaultBackground);

    final resolvedBorder = effectiveSelected
        ? (selectedBorderColor ?? borderColor ?? defaultBorder)
        : (borderColor ?? defaultBorder);

    final disabledForeground =
        theme.disabledColor.withValues(alpha: 0.85);
    final disabledBackground =
        colorScheme.surfaceContainerHighest.withValues(alpha: 0.45);
    final disabledBorder =
        colorScheme.outline.withValues(alpha: 0.28);

    final textStyle = (compact
            ? theme.textTheme.bodySmall
            : theme.textTheme.bodyMedium)
        ?.copyWith(
      color: effectiveEnabled ? resolvedForeground : disabledForeground,
      fontWeight: FontWeight.w600,
    );

    final iconColor = effectiveEnabled ? resolvedForeground : disabledForeground;

    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: compact ? 8 : 10,
          ),
      decoration: BoxDecoration(
        color: effectiveEnabled ? resolvedBackground : disabledBackground,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: effectiveEnabled ? resolvedBorder : disabledBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: compact ? 14 : 16,
              color: iconColor,
            ),
            SizedBox(width: compact ? 6 : 8),
          ],
          Text(label, style: textStyle),
          if (trailing != null) ...[
            SizedBox(width: compact ? 6 : 8),
            IconTheme(
              data: IconThemeData(
                size: compact ? 14 : 16,
                color: iconColor,
              ),
              child: DefaultTextStyle(
                style: textStyle ?? const TextStyle(),
                child: trailing!,
              ),
            ),
          ],
        ],
      ),
    );

    if (!effectiveEnabled) {
      return child;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: child,
      ),
    );
  }
}