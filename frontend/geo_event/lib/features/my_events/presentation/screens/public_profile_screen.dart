import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/profile/data/public_users_api.dart';
import '../../../../shared/profile/models/public_user_profile.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load profile.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        data: (profile) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
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
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.12),
                      backgroundImage:
                          (profile.imageUrl?.trim().isNotEmpty ?? false)
                              ? NetworkImage(profile.imageUrl!.trim())
                              : null,
                      child: (profile.imageUrl?.trim().isNotEmpty ?? false)
                          ? null
                          : Text(
                              _firstLetter(profile.fullName),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile.fullName.isNotEmpty ? profile.fullName : 'Unknown user',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.username.trim().isNotEmpty
                          ? '@${profile.username}'
                          : 'No username',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
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

  static String _firstLetter(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }
}