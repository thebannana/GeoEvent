import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/async/app_async_view.dart';
import '../../../../core/widgets/feedback/app_error_state.dart';
import '../../../../core/widgets/feedback/app_loading_indicator.dart';
import '../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../core/widgets/surfaces/app_surface_card.dart';
import '../../../../shared/profile/data/public_users_api.dart';
import '../../../../shared/profile/models/public_user_profile.dart';
import '../../../event/presentation/widgets/user_initials.dart';

final publicProfileProvider =
    FutureProvider.family<PublicUserProfileDto, int>((ref, userId) {
  return ref.watch(publicUsersApiProvider).getPublicProfile(userId);
});

class PublicProfileScreen extends ConsumerWidget {
  final int userId;

  const PublicProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicProfileProvider(userId));

    return AppScaffold(
      appBar: AppBar(title: const Text('Profile')),
      child: AppAsyncView<PublicUserProfileDto>(
        value: profileAsync,
        loading: const AppLoadingIndicator(
          title: 'Loading profile',
          message: 'Please wait while we fetch this profile.',
        ),
        errorBuilder: (error, stackTrace) {
          AppLogger.error(
            'Failed to load public profile.',
            tag: 'PublicProfileScreen',
            error: error,
            stackTrace: stackTrace,
          );

          return const AppErrorState(
            title: 'Could not load profile',
            message: 'Please try again later.',
          );
        },
        data: (profile) {
          final imageUrl = profile.imageUrl?.trim();
          final fullName = profile.fullName.trim();
          final username = profile.username.trim();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppSurfaceCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.12),
                      backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                          ? NetworkImage(imageUrl)
                          : null,
                      child: (imageUrl != null && imageUrl.isNotEmpty)
                          ? null
                          : Text(
                              UserInitials.from(
                                fullName.isNotEmpty ? fullName : username,
                                fallback: '?',
                              ),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      fullName.isNotEmpty ? fullName : 'Unknown user',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      username.isNotEmpty ? '@$username' : 'No username',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (profile.isVerified) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF43A047).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Verified',
                          style: TextStyle(
                            color: Color(0xFF43A047),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}