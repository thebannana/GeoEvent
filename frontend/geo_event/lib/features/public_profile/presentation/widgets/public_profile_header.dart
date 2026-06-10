import 'package:flutter/material.dart';

import '../../../../shared/public_profile/models/public_profile_user.dart';

class PublicProfileHeader extends StatelessWidget {
  final PublicProfileUser user;

  const PublicProfileHeader({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101215) : const Color(0xFFF6F8FC),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            backgroundImage:
                user.imageUrl != null && user.imageUrl!.trim().isNotEmpty
                    ? NetworkImage(user.imageUrl!)
                    : null,
            child: user.imageUrl == null || user.imageUrl!.trim().isEmpty
                ? Text(
                    user.fullName.isNotEmpty
                        ? user.fullName.characters.first.toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  user.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '@${user.username}',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          if ((user.cityName ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              user.cityName!,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
          if ((user.bio ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              user.bio!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}