import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_mode_controller.dart';
import '../../../../core/widgets/feedback/app_spinner.dart';
import '../../../../core/widgets/inputs/app_chip.dart';
import '../../../../shared/profile/models/user_profile.dart';
import '../widgets/profile_section.dart';

class ProfileScreen extends ConsumerWidget {
  final UserProfile profile;
  final VoidCallback onEditProfile;
  final VoidCallback onChangePassword;
  final VoidCallback onOpenBookmarks;
  final VoidCallback onOpenMyEvents;
  final VoidCallback onOpenPreferences;
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
    required this.onRevokeAllSessions,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeControllerProvider);
    final themeController = ref.read(themeModeControllerProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileHeader(profile: profile),
          const SizedBox(height: 24),
          AccountSection(
            profile: profile,
            onEditProfile: onEditProfile,
          ),
          LibrarySection(
            onOpenTicketScanner: onOpenTicketScanner,
            onOpenBookmarks: onOpenBookmarks,
            onOpenMyEvents: onOpenMyEvents,
          ),
          SecuritySection(
            onChangePassword: onChangePassword,
            onRevokeAllSessions: onRevokeAllSessions,
          ),
          PreferencesSection(
            themeMode: themeMode,
            onOpenPreferences: onOpenPreferences,
            onThemeChanged: themeController.setThemeMode,
          ),
          SessionSection(
            logoutColor: colors.error,
            onLogout: onLogout,
          ),
        ],
      ),
    );
  }

  static String themeModeLabel(ThemeMode mode) {
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

class AccountSection extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onEditProfile;

  const AccountSection({
    super.key,
    required this.profile,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileSection(
      title: 'Account',
      subtitle: 'Your personal and account information.',
      children: [
        ProfileInfoTile(
          icon: Icons.person_outline_rounded,
          title: 'Full name',
          subtitle: profile.displayFullName,
        ),
        ProfileInfoTile(
          icon: Icons.alternate_email_rounded,
          title: 'Username',
          subtitle: profile.displayUsername,
        ),
        ProfileInfoTile(
          icon: Icons.mail_outline_rounded,
          title: 'Email',
          subtitle: profile.displayEmail,
        ),
        ProfileInfoTile(
          icon: Icons.phone_outlined,
          title: 'Phone number',
          subtitle: profile.displayPhoneNumber,
        ),
        ProfileActionTile(
          icon: Icons.edit_outlined,
          title: 'Edit profile',
          subtitle: 'Update your personal details and image.',
          onTap: onEditProfile,
        ),
      ],
    );
  }
}

class LibrarySection extends StatelessWidget {
  final VoidCallback onOpenTicketScanner;
  final VoidCallback onOpenBookmarks;
  final VoidCallback onOpenMyEvents;

  const LibrarySection({
    super.key,
    required this.onOpenTicketScanner,
    required this.onOpenBookmarks,
    required this.onOpenMyEvents,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileSection(
      title: 'Library',
      subtitle: 'Your saved and created content.',
      children: [
        ProfileActionTile(
          icon: Icons.qr_code_scanner_rounded,
          title: 'Ticket scanner',
          subtitle: 'Scan and validate reservations for events.',
          onTap: onOpenTicketScanner,
        ),
        ProfileActionTile(
          icon: Icons.bookmark_border_rounded,
          title: 'Bookmarks',
          subtitle: 'Saved events and places.',
          onTap: onOpenBookmarks,
        ),
        ProfileActionTile(
          icon: Icons.event_note_rounded,
          title: 'My events',
          subtitle: 'Events you created or manage.',
          onTap: onOpenMyEvents,
        ),
      ],
    );
  }
}

class SecuritySection extends StatelessWidget {
  final VoidCallback onChangePassword;
  final VoidCallback onRevokeAllSessions;

  const SecuritySection({
    super.key,
    required this.onChangePassword,
    required this.onRevokeAllSessions,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileSection(
      title: 'Security',
      subtitle: 'Password and session management.',
      children: [
        ProfileActionTile(
          icon: Icons.lock_outline_rounded,
          title: 'Change password',
          subtitle: 'Update your account password securely.',
          onTap: onChangePassword,
        ),
        ProfileActionTile(
          icon: Icons.devices_outlined,
          title: 'Revoke all sessions',
          subtitle: 'Sign out from all other devices.',
          onTap: onRevokeAllSessions,
        ),
      ],
    );
  }
}

class PreferencesSection extends StatelessWidget {
  final ThemeMode themeMode;
  final VoidCallback onOpenPreferences;
  final ValueChanged<ThemeMode> onThemeChanged;

  const PreferencesSection({
    super.key,
    required this.themeMode,
    required this.onOpenPreferences,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileSection(
      title: 'Preferences',
      subtitle: 'Notifications, appearance, and activity.',
      children: [
        ProfileActionTile(
          icon: Icons.tune_rounded,
          title: 'Preferences',
          subtitle: 'Manage your app settings and notifications.',
          onTap: onOpenPreferences,
        ),
        ProfileInfoTile(
          icon: Icons.palette_outlined,
          title: 'Appearance',
          subtitle: ProfileScreen.themeModeLabel(themeMode),
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
                        onThemeChanged(selection.first);
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
    );
  }
}

class SessionSection extends StatelessWidget {
  final Color logoutColor;
  final VoidCallback onLogout;

  const SessionSection({
    super.key,
    required this.logoutColor,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileSection(
      title: 'Session',
      subtitle: 'Current account session controls.',
      children: [
        ProfileActionTile(
          icon: Icons.logout_rounded,
          iconColor: logoutColor,
          title: 'Log out',
          titleColor: logoutColor,
          subtitle: 'End your current session.',
          onTap: onLogout,
        ),
      ],
    );
  }
}

class ProfileHeader extends StatelessWidget {
  final UserProfile profile;

  const ProfileHeader({
    super.key,
    required this.profile,
  });

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
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.surfaceContainerHighest,
                border: Border.all(color: colors.outlineVariant),
              ),
              child: ClipOval(
                child: profile.hasProfileImage
                    ? Image.network(
                        profile.imageUrl!.trim(),
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: AppSpinner(size: 22, strokeWidth: 2),
                          );
                        },
                        errorBuilder: (_, _, _) => ProfileAvatarFallback(
                          color: colors.primary,
                        ),
                      )
                    : ProfileAvatarFallback(
                        color: colors.primary,
                      ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              profile.displayHeaderName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              profile.displayUsername,
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
                AppChip(
                  icon: Icons.calendar_today_outlined,
                  label: 'Joined ${profile.displayJoinedYear}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileAvatarFallback extends StatelessWidget {
  final Color color;

  const ProfileAvatarFallback({
    super.key,
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

class ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const ProfileInfoTile({
    super.key,
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

class ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final Color? titleColor;
  final String subtitle;
  final VoidCallback? onTap;

  const ProfileActionTile({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    this.titleColor,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onTap != null;

    final effectiveIconColor = enabled
        ? iconColor
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45);

    final effectiveTitleStyle = titleColor != null
        ? TextStyle(
            color: enabled
                ? titleColor
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
          )
        : !enabled
            ? TextStyle(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
              )
            : null;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: effectiveIconColor),
      title: Text(title, style: effectiveTitleStyle),
      subtitle: Text(subtitle),
      trailing: enabled
          ? const Icon(Icons.chevron_right_rounded)
          : Icon(
              Icons.block_rounded,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
            ),
      onTap: onTap,
    );
  }
}