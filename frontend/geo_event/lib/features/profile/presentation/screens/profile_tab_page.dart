import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/application/auth_controller.dart';
import '../../application/profile_controller.dart';
import 'activity_logs_screen.dart';
import 'bookmarks_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'my_events_screen.dart';
import 'preferences_screen.dart';
import 'profile_screen.dart';
import 'ticket_scanner_entry_screen.dart';

class ProfileTabPage extends ConsumerWidget {
  const ProfileTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return profileAsync.when(
      data: (profile) {
        return ProfileScreen(
          profile: profile,
          onEditProfile: () async {
            final result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => EditProfileScreen(profile: profile),
              ),
            );

            if (result == true) {
              await ref
                  .read(profileControllerProvider.notifier)
                  .refreshProfile();
            }
          },
          onChangePassword: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ChangePasswordScreen(),
              ),
            );
          },
          onOpenBookmarks: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const BookmarksScreen(),
              ),
            );
          },
          onOpenMyEvents: () async {
            await Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (_) => const MyEventsScreen(),
              ),
            );
          },
          onOpenPreferences: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PreferencesScreen(),
              ),
            );
          },
          onOpenActivityLogs: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ActivityLogsScreen(),
              ),
            );
          },
          onOpenTicketScanner: () async {
            await Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (_) => const TicketScannerEntryScreen(),
              ),
            );
          },
          onRevokeAllSessions: () async {
            try {
              await ref
                  .read(profileControllerProvider.notifier)
                  .revokeAllSessions();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All sessions revoked successfully.'),
                  ),
                );
              }
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to revoke sessions.'),
                  ),
                );
              }
            }
          },
          onLogout: () async {
            try {
              await ref.read(authStateProvider.notifier).logout();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged out successfully.')),
                );
              }
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to log out.')),
                );
              }
            }
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF17191D) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF2A303A)
                    : const Color(0xFFE5EAF2),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 30,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Failed to load profile',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$error',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 14),
                TextButton.icon(
                  onPressed: () {
                    ref.invalidate(profileControllerProvider);
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}