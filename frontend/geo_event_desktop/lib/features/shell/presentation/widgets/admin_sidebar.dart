import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../shared/shell/models/admin_shell_models.dart';

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    super.key,
    required this.isExpanded,
    required this.selectedPage,
    required this.onToggle,
    required this.onSelectPage,
    required this.onLogout,
  });

  final bool isExpanded;
  final AdminShellPage selectedPage;
  final VoidCallback onToggle;
  final ValueChanged<AdminShellPage> onSelectPage;
  final VoidCallback onLogout;

  Future<void> _confirmLogout(BuildContext context) async {
    final colors = Theme.of(context).appColors;
    final colorScheme = Theme.of(context).colorScheme;

    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.surface,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Logout',
            style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      onLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          right: BorderSide(color: colors.border),
        ),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(
          begin: isExpanded ? 84 : 250,
          end: isExpanded ? 250 : 84,
        ),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        builder: (context, width, child) {
          return SizedBox(
            width: width,
            child: child,
          );
        },
        child: Column(
          children: [
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Material(
                  color: colors.inputFill,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: onToggle,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        isExpanded
                            ? Icons.keyboard_double_arrow_left_rounded
                            : Icons.keyboard_double_arrow_right_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Section(
                      title: null,
                      isExpanded: isExpanded,
                      children: AdminShellItems.menu.map((item) {
                        return _SidebarItem(
                          item: item,
                          isExpanded: isExpanded,
                          isSelected: selectedPage == item.page,
                          onTap: () => onSelectPage(item.page),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 22),
                    _Section(
                      title: 'General',
                      isExpanded: isExpanded,
                      children: [
                        ...AdminShellItems.general.map((item) {
                          return _SidebarItem(
                            item: item,
                            isExpanded: isExpanded,
                            isSelected: selectedPage == item.page,
                            onTap: () => onSelectPage(item.page),
                          );
                        }),
                        _LogoutItem(
                          isExpanded: isExpanded,
                          onTap: () => _confirmLogout(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.isExpanded,
    required this.children,
  });

  final String? title;
  final bool isExpanded;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final hasTitle = title != null && title!.isNotEmpty;
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment:
          isExpanded ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        if (isExpanded && hasTitle)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              title!,
              style: textTheme.titleMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
          ),
        if (isExpanded && hasTitle) const SizedBox(height: 10),
        ...children,
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.item,
    required this.isExpanded,
    required this.isSelected,
    required this.onTap,
  });

  final AdminNavItem item;
  final bool isExpanded;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final selectedTextColor = colors.textPrimary;
    final selectedIconColor = colorScheme.primary;
    final unselectedColor = colors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            height: 48,
            padding: EdgeInsets.symmetric(
              horizontal: isExpanded ? 10 : 0,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: isSelected
                  ? Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.22),
                    )
                  : null,
            ),
            child: Row(
              mainAxisAlignment: isExpanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                if (isSelected)
                  Container(
                    width: 4,
                    height: 28,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: selectedIconColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  )
                else if (isExpanded)
                  const SizedBox(width: 14),
                Icon(
                  item.icon,
                  size: 22,
                  color: isSelected ? selectedIconColor : unselectedColor,
                ),
                if (isExpanded) const SizedBox(width: 12),
                if (isExpanded)
                  Expanded(
                    child: Text(
                      item.label,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        color:
                            isSelected ? selectedTextColor : unselectedColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutItem extends StatelessWidget {
  const _LogoutItem({
    required this.isExpanded,
    required this.onTap,
  });

  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            height: 48,
            padding: EdgeInsets.symmetric(
              horizontal: isExpanded ? 10 : 0,
            ),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: isExpanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                if (isExpanded) const SizedBox(width: 14),
                Icon(
                  Icons.logout_rounded,
                  size: 22,
                  color: colors.textSecondary,
                ),
                if (isExpanded) const SizedBox(width: 12),
                if (isExpanded)
                  Expanded(
                    child: Text(
                      'Logout',
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}