import 'package:flutter/material.dart';

class AppChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;

  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final foregroundColor =
        selected ? colorScheme.primary : colorScheme.onSurface;
    final backgroundColor = selected
        ? colorScheme.primary.withValues(alpha: 0.14)
        : colorScheme.surface.withValues(alpha: 0.82);

    final borderColor = selected
        ? colorScheme.primary.withValues(alpha: 0.35)
        : colorScheme.outline.withValues(alpha: 0.65);

    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: foregroundColor,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return child;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: child,
      ),
    );
  }
}