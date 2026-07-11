import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/async/app_async_view.dart';
import '../../../../core/widgets/feedback/app_confirm_dialog.dart';
import '../../../../core/widgets/feedback/app_error_state.dart';
import '../../../../core/widgets/feedback/app_loading_indicator.dart';
import '../../../../shared/bookmarks/application/bookmark_controller.dart';
import '../../../../shared/likes/providers/liked_events_providers.dart';
import '../../../../shared/profile/providers/profile_providers.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../inbox/application/inbox_controller.dart';
import '../../../reservations/application/reservations_controller.dart';
import '../../application/profile_controller.dart';
import 'bookmarks_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'my_events_screen.dart';
import 'preferences_screen.dart';
import 'profile_screen.dart';
import 'ticket_scanner_entry_screen.dart';

class ProfileTabPage extends ConsumerStatefulWidget {
  const ProfileTabPage({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  ConsumerState<ProfileTabPage> createState() => _ProfileTabPageState();

  static Future<T?> push<T>(
    BuildContext context,
    Widget screen, {
    bool useRootNavigator = false,
  }) {
    return Navigator.of(
      context,
      rootNavigator: useRootNavigator,
    ).push<T>(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  static Future<bool> confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    bool isDestructive = false,
  }) {
    return AppConfirmDialog.show(
      context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      destructive: isDestructive,
    );
  }

  static void clearSessionScopedProviders(WidgetRef ref) {
    ref.invalidate(profileControllerProvider);
    ref.invalidate(myPreferencesProvider);
    ref.invalidate(bookmarksProvider);
    ref.invalidate(likedEventsProvider);
    ref.invalidate(reservationsControllerProvider);
    ref.invalidate(inboxControllerProvider);
  }

  static void showSnackBar(
    BuildContext context, {
    required String message,
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }
}

class _ProfileTabPageState extends ConsumerState<ProfileTabPage> {
  @override
  Widget build(BuildContext context) {
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
              message: ErrorMapper.toMessage(
                error,
                stackTrace: stackTrace,
                fallbackMessage: 'Please try again.',
              ),
              onRetry: () => ref.invalidate(profileControllerProvider),
            ),
          ),
        );
      },
      data: (profile) {
        return ProfileScreen(
          profile: profile,
          onEditProfile: () async {
            final didUpdate = await ProfileTabPage.push<bool>(
              context,
              EditProfileScreen(profile: profile),
            );
            if (didUpdate == true) {
              await ref.read(profileControllerProvider.notifier).refreshProfile();
            }
          },
          onChangePassword: () {
            ProfileTabPage.push<void>(context, const ChangePasswordScreen());
          },
          onOpenBookmarks: () {
            ProfileTabPage.push<void>(context, const BookmarksScreen());
          },
          onOpenMyEvents: () {
            ProfileTabPage.push<void>(
              context,
              const MyEventsScreen(),
              useRootNavigator: true,
            );
          },
          onOpenPreferences: () {
            ProfileTabPage.push<void>(context, const PreferencesScreen());
          },
          onOpenTicketScanner: () {
            ProfileTabPage.push<void>(
              context,
              const TicketScannerEntryScreen(),
              useRootNavigator: true,
            );
          },
          onRevokeAllSessions: () async {
            final confirmed = await ProfileTabPage.confirmAction(
              context,
              title: 'Revoke all sessions?',
              message:
                  'All other devices will be signed out. Your current session will remain active.',
              confirmLabel: 'Revoke',
            );

            if (!confirmed || !context.mounted) return;

            try {
              await ref
                  .read(profileControllerProvider.notifier)
                  .revokeAllSessions();

              ProfileTabPage.showSnackBar(
                context,
                message: 'All other sessions were revoked successfully.',
              );
            } catch (error, stackTrace) {
              AppLogger.error(
                'Failed to revoke all sessions.',
                tag: 'ProfileTabPage',
                error: error,
                stackTrace: stackTrace,
              );

              ProfileTabPage.showSnackBar(
                context,
                message: ErrorMapper.toMessage(
                  error,
                  stackTrace: stackTrace,
                  fallbackMessage: 'Failed to revoke sessions.',
                ),
              );
            }
          },
          onLogout: () async {
            final confirmed = await ProfileTabPage.confirmAction(
              context,
              title: 'Log out?',
              message: 'Your current session will be ended on this device.',
              confirmLabel: 'Log out',
              isDestructive: true,
            );

            if (!confirmed || !context.mounted) return;

            try {
              await ref.read(authStateProvider.notifier).logout();
              ProfileTabPage.clearSessionScopedProviders(ref);

              widget.onClose?.call();

              if (!context.mounted) return;

              ProfileTabPage.showSnackBar(
                context,
                message: 'Logged out successfully.',
              );
            } catch (error, stackTrace) {
              AppLogger.error(
                'Failed to log out.',
                tag: 'ProfileTabPage',
                error: error,
                stackTrace: stackTrace,
              );

              ProfileTabPage.showSnackBar(
                context,
                message: ErrorMapper.toMessage(
                  error,
                  stackTrace: stackTrace,
                  fallbackMessage: 'Failed to log out.',
                ),
              );
            }
          },
        );
      },
    );
  }
}