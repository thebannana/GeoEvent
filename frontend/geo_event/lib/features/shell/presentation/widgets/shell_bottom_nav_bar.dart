import 'package:flutter/material.dart';

import '../../domain/shell_tab.dart';
import 'shell_create_nav_item.dart';
import 'shell_nav_item.dart';

class ShellBottomNavBar extends StatelessWidget {
  final ShellTab? selectedTab;
  final ValueChanged<ShellTab> onTap;

  const ShellBottomNavBar({
    super.key,
    required this.selectedTab,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Container(
          height: 82,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161A21) : const Color(0xFFF9FBFD),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF2A303A)
                  : const Color(0xFFE3EAF3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.08),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ShellNavItem(
                label: 'Chat',
                icon: Icons.chat_bubble_outline_rounded,
                selected: selectedTab == ShellTab.chat,
                onTap: () => onTap(ShellTab.chat),
              ),
              ShellNavItem(
                label: 'Bookings',
                icon: Icons.confirmation_num_outlined,
                selected: selectedTab == ShellTab.reservations,
                onTap: () => onTap(ShellTab.reservations),
              ),
              ShellCreateNavItem(
                selected: selectedTab == ShellTab.createEvent,
                onTap: () => onTap(ShellTab.createEvent),
              ),
              ShellNavItem(
                label: 'Inbox',
                icon: Icons.notifications_outlined,
                selected: selectedTab == ShellTab.inbox,
                onTap: () => onTap(ShellTab.inbox),
              ),
              ShellNavItem(
                label: 'Profile',
                icon: Icons.person_outline_rounded,
                selected: selectedTab == ShellTab.profile,
                onTap: () => onTap(ShellTab.profile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}