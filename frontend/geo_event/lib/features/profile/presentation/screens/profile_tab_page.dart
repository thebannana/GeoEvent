import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/profile_controller.dart';
import 'activity_logs_screen.dart';
import 'bookmarks_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'my_events_screen.dart';
import 'preferences_screen.dart';
import 'profile_screen.dart';

class ProfileTabPage extends ConsumerWidget {
  const ProfileTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileControllerProvider);

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
              await ref.read(profileControllerProvider.notifier).refreshProfile();
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
            await Navigator.of(context).push(
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
          onRevokeAllSessions: () async {
            try {
              await ref.read(profileControllerProvider.notifier).revokeAllSessions();

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
          onLogout: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Logout flow will be connected next.'),
              ),
            );
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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 40),
              const SizedBox(height: 12),
              const Text(
                'Failed to load profile.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                '$error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  ref.invalidate(profileControllerProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}