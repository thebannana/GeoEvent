import 'package:flutter/material.dart';

class SearchSheetChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool showArrow;

  const SearchSheetChip({
    super.key,
    required this.label,
    this.onTap,
    this.isSelected = false,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bgColor = isSelected
        ? colorScheme.primary.withValues(alpha: 0.10)
        : colorScheme.surface;

    final borderColor = isSelected
        ? colorScheme.primary.withValues(alpha: 0.65)
        : colorScheme.outline.withValues(alpha: 0.75);

    final textColor = isSelected
        ? colorScheme.primary
        : colorScheme.onSurface.withValues(alpha: 0.72);

    final iconColor = isSelected
        ? colorScheme.primary
        : colorScheme.onSurface.withValues(alpha: 0.48);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: textColor,
                ),
              ),
              if (showArrow) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: iconColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}