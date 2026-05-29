import 'package:flutter/material.dart';

class ShellCreateNavItem extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const ShellCreateNavItem({
    super.key,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedColor = theme.colorScheme.primary;

    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: selectedColor,
              shape: const CircleBorder(),
              elevation: selected ? 6 : 4,
              shadowColor: selectedColor.withValues(alpha: 0.35),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: selectedColor.withValues(
                          alpha: isDark ? 0.30 : 0.22,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}