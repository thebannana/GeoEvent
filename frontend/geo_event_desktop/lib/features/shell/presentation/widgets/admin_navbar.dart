import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../shared/admin_profile/models/user_profile.dart';
import '../../application/profile_controller.dart';

class AdminNavbar extends ConsumerWidget {
  const AdminNavbar({
    super.key,
    required this.onAccountSelected,
    required this.searchController,
  });

  final ValueChanged<String> onAccountSelected;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final profileState = ref.watch(profileControllerProvider);
    final profile = profileState.asData?.value;

    final displayName = _displayName(profile);
    final avatarLabel = _avatarLabel(profile);

    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(color: colors.border),
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/geoevent.png',
            height: 36,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SizedBox(
                  height: 44,
                  child: TextField(
                    controller: searchController,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: colors.inputFill,
                      hoverColor: colors.inputFill,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      hintText: 'Search for anything',
                      hintStyle: textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary.withValues(alpha: 0.72),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 20,
                        color: colors.textSecondary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: colors.borderSoft),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: colors.borderSoft),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          PopupMenuButton<String>(
  tooltip: 'Account',
  offset: const Offset(0, 52),
  color: colors.card,
  elevation: 10,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  ),
  onSelected: onAccountSelected,
  itemBuilder: (context) => [
    PopupMenuItem<String>(
      value: 'password',
      mouseCursor: SystemMouseCursors.click,
      child: ListTile(
        mouseCursor: SystemMouseCursors.click,
        leading: Icon(
          Icons.lock_outline,
          color: colors.textSecondary,
        ),
        title: Text(
          'Change password',
          style: textTheme.bodyMedium?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        contentPadding: EdgeInsets.zero,
      ),
    ),
    PopupMenuItem<String>(
      value: 'info',
      mouseCursor: SystemMouseCursors.click,
      child: ListTile(
        mouseCursor: SystemMouseCursors.click,
        leading: Icon(
          Icons.person_outline,
          color: colors.textSecondary,
        ),
        title: Text(
          'Change account information',
          style: textTheme.bodyMedium?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        contentPadding: EdgeInsets.zero,
      ),
    ),
  ],
  child: MouseRegion(
    cursor: SystemMouseCursors.click,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: colors.inputFill.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _NavbarAvatar(
            imageUrl: profile?.imageUrl,
            fallbackLabel: avatarLabel,
          ),
          const SizedBox(width: 10),
          Text(
            displayName,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: colors.textSecondary,
          ),
        ],
      ),
    ),
  ),
),
        ],
      ),
    );
  }

  String _displayName(UserProfile? profile) {
    final username = profile?.username.trim() ?? '';
    if (username.isNotEmpty) return username;

    final fullName = profile?.fullName.trim() ?? '';
    if (fullName.isNotEmpty) return fullName;

    return 'Account';
  }

  String _avatarLabel(UserProfile? profile) {
    final source = [
      profile?.firstName ?? '',
      profile?.lastName ?? '',
      profile?.username ?? '',
      profile?.email ?? '',
    ].firstWhere(
      (value) => value.trim().isNotEmpty,
      orElse: () => 'A',
    );

    return source.trim().characters.first.toUpperCase();
  }
}

class _NavbarAvatar extends StatelessWidget {
  const _NavbarAvatar({
    required this.imageUrl,
    required this.fallbackLabel,
  });

  final String? imageUrl;
  final String fallbackLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final trimmedUrl = imageUrl?.trim();

    return CircleAvatar(
      radius: 18,
      backgroundColor: colors.inputFill,
      backgroundImage: trimmedUrl != null && trimmedUrl.isNotEmpty
          ? NetworkImage(trimmedUrl)
          : null,
      child: trimmedUrl == null || trimmedUrl.isEmpty
          ? Text(
              fallbackLabel,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            )
          : null,
    );
  }
}