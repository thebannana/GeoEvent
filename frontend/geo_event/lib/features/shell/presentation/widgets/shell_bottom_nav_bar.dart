import 'package:flutter/material.dart';

import '../../../../shared/shell/models/shell_tab.dart';
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
    final colorScheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Container(
          height: 82,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.75),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.14),
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
                icon: Icons.inbox_outlined,
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