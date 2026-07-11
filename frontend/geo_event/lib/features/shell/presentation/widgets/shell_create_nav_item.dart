import 'package:flutter/material.dart';

class ShellCreateNavItem extends StatelessWidget {
  static const String _tooltip = 'Create event';

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
    final selectedColor = theme.colorScheme.primary;

    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: _tooltip,
              child: Semantics(
                button: true,
                selected: selected,
                label: _tooltip,
                child: Material(
                  color: selectedColor,
                  shape: const CircleBorder(),
                  elevation: selected ? 6 : 4,
                  shadowColor: selectedColor.withValues(alpha: 0.30),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onTap,
                    child: const SizedBox(
                      width: 54,
                      height: 54,
                      child: Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
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