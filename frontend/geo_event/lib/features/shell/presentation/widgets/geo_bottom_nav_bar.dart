import 'dart:ui';
import 'package:flutter/material.dart';
import '../../domain/shell_tab.dart';

class GeoBottomNavBar extends StatelessWidget {
  final ShellTab? selectedTab;
  final void Function(ShellTab) onTap;

  const GeoBottomNavBar({
    super.key,
    required this.selectedTab,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.52)
                : Colors.white.withValues(alpha: 0.60),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.09)
                    : Colors.white.withValues(alpha: 0.70),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 68,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ShellTab.values.map((tab) {
                  return _NavItem(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    onTap: () => onTap(tab),
                    isDark: isDark,
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final ShellTab tab;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _NavItem({
    required this.tab,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  IconData get _icon {
    switch (tab) {
      case ShellTab.chat:
        return isSelected ? Icons.chat_bubble : Icons.chat_bubble_outline_rounded;
      case ShellTab.reservations:
        return isSelected ? Icons.confirmation_num : Icons.confirmation_num_outlined;
      case ShellTab.createEvent:
        return Icons.add_rounded;
      case ShellTab.inbox:
        return isSelected ? Icons.inbox_rounded : Icons.inbox_outlined;
      case ShellTab.profile:
        return isSelected ? Icons.person_rounded : Icons.person_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = tab == ShellTab.createEvent;
    final primary = Theme.of(context).colorScheme.primary;

    if (isCreate) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 58,
        height: 68,
        child: Center(
          child: AnimatedScale(
            scale: isSelected ? 1.18 : 1.0,
            duration: const Duration(milliseconds: 180),
            child: Icon(
              _icon,
              size: 24,
              color: isSelected
                  ? primary
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.40)
                      : Colors.black.withValues(alpha: 0.32)),
            ),
          ),
        ),
      ),
    );
  }
}