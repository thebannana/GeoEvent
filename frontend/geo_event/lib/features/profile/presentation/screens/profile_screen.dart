import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_mode_controller.dart';
import '../../../../shared/profile/models/user_profile.dart';
import '../widgets/profile_section.dart';

class ProfileScreen extends ConsumerWidget {
  final UserProfile profile;
  final VoidCallback onEditProfile;
  final VoidCallback onChangePassword;
  final VoidCallback onOpenBookmarks;
  final VoidCallback onOpenMyEvents;
  final VoidCallback onOpenPreferences;
  final VoidCallback onOpenActivityLogs;
  final VoidCallback onRevokeAllSessions;
  final VoidCallback onLogout;
  final VoidCallback onOpenTicketScanner;

const ProfileScreen({
  super.key,
  required this.profile,
  required this.onEditProfile,
  required this.onChangePassword,
  required this.onOpenBookmarks,
  required this.onOpenMyEvents,
  required this.onOpenTicketScanner,
  required this.onOpenPreferences,
  required this.onOpenActivityLogs,
  required this.onRevokeAllSessions,
  required this.onLogout,
});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final themeMode = ref.watch(themeModeControllerProvider);
    final themeController = ref.read(themeModeControllerProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileHeader(profile: profile),
          const SizedBox(height: 24),
          ProfileSection(
            title: 'Account',
            subtitle: 'Your personal and account information.',
            children: [
              _ProfileInfoTile(
                icon: Icons.person_outline_rounded,
                title: 'Full name',
                subtitle: profile.fullName.trim().isEmpty
                    ? 'Not set'
                    : profile.fullName,
              ),
              _ProfileInfoTile(
                icon: Icons.alternate_email_rounded,
                title: 'Username',
                subtitle: '@${profile.username}',
              ),
              _ProfileInfoTile(
                icon: Icons.mail_outline_rounded,
                title: 'Email',
                subtitle: profile.email,
              ),
              _ProfileInfoTile(
                icon: Icons.phone_outlined,
                title: 'Phone number',
                subtitle: (profile.phoneNumber ?? '').trim().isEmpty
                    ? 'Not set'
                    : profile.phoneNumber!,
              ),
              _ProfileActionTile(
                icon: Icons.edit_outlined,
                title: 'Edit profile',
                subtitle: 'Update your personal details and image.',
                onTap: onEditProfile,
              ),
            ],
          ),
          ProfileSection(
            title: 'Library',
            subtitle: 'Your saved and created content.',
            children: [
              _ProfileActionTile(
                icon: Icons.qr_code_scanner_rounded,
                title: 'Ticket scanner',
                subtitle: 'Scan and validate reservations for your events.',
                onTap: onOpenTicketScanner,
              ),
              _ProfileActionTile(
                icon: Icons.bookmark_border_rounded,
                title: 'Bookmarks',
                subtitle: 'Saved events and places.',
                onTap: onOpenBookmarks,
              ),
              _ProfileActionTile(
                icon: Icons.event_note_rounded,
                title: 'My events',
                subtitle: 'Events you created or manage.',
                onTap: onOpenMyEvents,
              ),
            ],
          ),
          ProfileSection(
            title: 'Security',
            subtitle: 'Password and session management.',
            children: [
              _ProfileActionTile(
                icon: Icons.lock_outline_rounded,
                title: 'Change password',
                subtitle: 'Update your account password securely.',
                onTap: onChangePassword,
              ),
              _ProfileActionTile(
                icon: Icons.devices_outlined,
                title: 'Revoke all sessions',
                subtitle: 'Sign out from all other devices.',
                onTap: onRevokeAllSessions,
              ),
            ],
          ),
          ProfileSection(
            title: 'Preferences',
            subtitle: 'Notifications, appearance, and activity.',
            children: [
              _ProfileActionTile(
                icon: Icons.tune_rounded,
                title: 'Preferences',
                subtitle: 'Manage your app settings and notifications.',
                onTap: onOpenPreferences,
              ),
              _ProfileInfoTile(
                icon: Icons.palette_outlined,
                title: 'Appearance',
                subtitle: _themeModeLabel(themeMode),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: Center(
                          child: SegmentedButton<ThemeMode>(
                            segments: const [
                              ButtonSegment<ThemeMode>(
                                value: ThemeMode.system,
                                icon: Icon(Icons.brightness_auto_rounded),
                                label: Text('System'),
                              ),
                              ButtonSegment<ThemeMode>(
                                value: ThemeMode.light,
                                icon: Icon(Icons.light_mode_rounded),
                                label: Text('Light'),
                              ),
                              ButtonSegment<ThemeMode>(
                                value: ThemeMode.dark,
                                icon: Icon(Icons.dark_mode_rounded),
                                label: Text('Dark'),
                              ),
                            ],
                            selected: {themeMode},
                            onSelectionChanged: (selection) {
                              if (selection.isEmpty) return;
                              themeController.setThemeMode(selection.first);
                            },
                            showSelectedIcon: false,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          ProfileSection(
            title: 'Session',
            subtitle: 'Current account session controls.',
            children: [
              _ProfileActionTile(
                icon: Icons.logout_rounded,
                iconColor: colors.error,
                title: 'Log out',
                titleColor: colors.error,
                subtitle: 'End your current session.',
                onTap: onLogout,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Follow your device theme.';
      case ThemeMode.light:
        return 'Light theme is enabled.';
      case ThemeMode.dark:
        return 'Dark theme is enabled.';
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserProfile profile;

  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final imageUrl = profile.imageUrl?.trim();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.surfaceContainerHighest,
                border: Border.all(
                  color: colors.outlineVariant,
                ),
              ),
              child: ClipOval(
                child: hasImage
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _ProfileAvatarFallback(
                          color: colors.primary,
                        ),
                      )
                    : _ProfileAvatarFallback(
                        color: colors.primary,
                      ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              profile.fullName.trim().isEmpty
                  ? profile.username
                  : profile.fullName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '@${profile.username}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _InfoChip(
                  icon: Icons.calendar_today_outlined,
                  label: 'Joined ${profile.createdAt?.year}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatarFallback extends StatelessWidget {
  final Color color;

  const _ProfileAvatarFallback({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.person_rounded,
        size: 38,
        color: color,
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ProfileInfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final Color? titleColor;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileActionTile({
    required this.icon,
    this.iconColor,
    required this.title,
    this.titleColor,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: titleColor != null ? TextStyle(color: titleColor) : null,
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}