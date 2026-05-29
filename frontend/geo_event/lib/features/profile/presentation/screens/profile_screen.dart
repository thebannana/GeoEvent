import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/profile/models/user_profile.dart';
import '../../../../core/theme/theme_mode_controller.dart';
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

  const ProfileScreen({
    super.key,
    required this.profile,
    required this.onEditProfile,
    required this.onChangePassword,
    required this.onOpenBookmarks,
    required this.onOpenMyEvents,
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
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline_rounded),
              title: const Text('Full name'),
              subtitle: Text(
                profile.fullName.isEmpty ? 'Not set' : profile.fullName,
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.alternate_email_rounded),
              title: const Text('Username'),
              subtitle: Text('@${profile.username}'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.mail_outline_rounded),
              title: const Text('Email'),
              subtitle: Text(profile.email),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.phone_outlined),
              title: const Text('Phone number'),
              subtitle: Text(
                (profile.phoneNumber ?? '').trim().isEmpty
                    ? 'Not set'
                    : profile.phoneNumber!,
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.badge_outlined),
              title: const Text('Role'),
              subtitle: Text(profile.role),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                profile.isVerified
                    ? Icons.verified_user_outlined
                    : Icons.error_outline_rounded,
                color: profile.isVerified ? colors.primary : colors.error,
              ),
              title: const Text('Verification'),
              subtitle: Text(
                profile.isVerified ? 'Verified account' : 'Email not verified',
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit profile'),
              subtitle: const Text('Update your personal details and image.'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: onEditProfile,
            ),
          ],
        ),
        ProfileSection(
          title: 'Library',
          subtitle: 'Your saved and created content.',
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.bookmark_border_rounded),
              title: const Text('Bookmarks'),
              subtitle: const Text('Saved events and places.'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: onOpenBookmarks,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_note_rounded),
              title: const Text('My events'),
              subtitle: const Text('Events you created or manage.'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: onOpenMyEvents,
            ),
          ],
        ),
        ProfileSection(
          title: 'Security',
          subtitle: 'Password and session management.',
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.lock_outline_rounded),
              title: const Text('Change password'),
              subtitle: const Text('Update your account password securely.'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: onChangePassword,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.devices_outlined),
              title: const Text('Revoke all sessions'),
              subtitle: const Text('Sign out from all other devices.'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: onRevokeAllSessions,
            ),
          ],
        ),
        ProfileSection(
          title: 'Preferences',
          subtitle: 'Notifications, appearance, and activity.',
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.tune_rounded),
              title: const Text('Preferences'),
              subtitle: const Text('Manage your app settings and notifications.'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: onOpenPreferences,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Appearance'),
              subtitle: Text(_themeModeLabel(themeMode)),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
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
                    themeController.setThemeMode(selection.first);
                  },
                  showSelectedIcon: false,
                ),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history_rounded),
              title: const Text('Activity log'),
              subtitle: const Text('Review your recent account activity.'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: onOpenActivityLogs,
            ),
          ],
        ),
        ProfileSection(
          title: 'Session',
          subtitle: 'Current account session controls.',
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.logout_rounded, color: colors.error),
              title: Text(
                'Log out',
                style: TextStyle(color: colors.error),
              ),
              subtitle: const Text('End your current session.'),
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

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: colors.surfaceContainerHighest,
              backgroundImage:
                  (profile.imageUrl != null && profile.imageUrl!.trim().isNotEmpty)
                      ? NetworkImage(profile.imageUrl!)
                      : null,
              child: (profile.imageUrl == null || profile.imageUrl!.trim().isEmpty)
                  ? Icon(
                      Icons.person_rounded,
                      size: 38,
                      color: colors.primary,
                    )
                  : null,
            ),
            const SizedBox(height: 14),
            Text(
              profile.fullName.isEmpty ? profile.username : profile.fullName,
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
                  icon: profile.isVerified
                      ? Icons.verified_rounded
                      : Icons.info_outline_rounded,
                  label: profile.isVerified ? 'Verified' : 'Unverified',
                ),
                _InfoChip(
                  icon: Icons.shield_outlined,
                  label: profile.role,
                ),
                _InfoChip(
                  icon: Icons.calendar_today_outlined,
                  label: 'Joined ${profile.createdAt.year}',
                ),
              ],
            ),
          ],
        ),
      ),
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