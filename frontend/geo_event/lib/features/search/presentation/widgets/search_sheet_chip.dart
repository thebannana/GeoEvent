import 'package:flutter/material.dart';

class SearchSheetChip extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback? onTap;
  final bool isSelected;

  const SearchSheetChip({
    super.key,
    required this.label,
    required this.isDark,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected
        ? (isDark ? const Color(0xFF253041) : const Color(0xFFEAF2FF))
        : (isDark ? const Color(0xFF1B2028) : Colors.white);

    final borderColor = isSelected
        ? const Color(0xFF6B8FBF)
        : (isDark ? const Color(0xFF2A303A) : const Color(0xFFE3EAF3));

    final textColor = isSelected
        ? (isDark ? Colors.white : const Color(0xFF365D92))
        : (isDark ? Colors.white70 : Colors.black54);

    final iconColor = isSelected
        ? (isDark ? Colors.white70 : const Color(0xFF365D92))
        : (isDark ? Colors.white38 : Colors.black38);

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
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: iconColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}