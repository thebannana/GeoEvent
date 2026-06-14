import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_async_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../shared/bookmarks/providers/bookmark_providers.dart';
import '../../../../shared/likes/providers/liked_events_providers.dart';
import '../../../../shared/notifications/providers/notification_providers.dart';
import '../../../../shared/profile/providers/profile_providers.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../inbox/application/inbox_controller.dart';
import '../../../reservations/application/reservations_controller.dart';
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

    return AppAsyncView(
      value: profileAsync,
      loading: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: AppLoadingIndicator(
            title: 'Loading profile',
            message: 'Please wait while we prepare your account details.',
            centered: false,
            padding: EdgeInsets.zero,
          ),
        ),
      ),
      errorBuilder: (error, stackTrace) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AppErrorState(
              title: 'Failed to load profile',
              message: error.toString(),
              onRetry: () {
                ref.invalidate(profileControllerProvider);
              },
            ),
          ),
        );
      },
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

              ref.invalidate(profileControllerProvider);
              ref.invalidate(myProfileProvider);
              ref.invalidate(myPreferencesProvider);
              ref.invalidate(bookmarksProvider);
              ref.invalidate(likedEventsProvider);
              ref.invalidate(unreadNotificationCountProvider);
              ref.invalidate(notificationsControllerProvider);
              ref.invalidate(reservationsControllerProvider);

              // If your inbox screen uses the separate InboxController from the other file:
              ref.invalidate(inboxControllerProvider);

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
    );
  }
}