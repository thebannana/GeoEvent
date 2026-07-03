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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final fullName = user.fullName.trim();
    final username = user.username.trim();
    final bio = (user.bio ?? '').trim();
    final imageUrl = (user.imageUrl ?? '').trim();

    final displayName = fullName.isNotEmpty ? fullName : '@$username';
    final initialsSource = fullName.isNotEmpty ? fullName : username;
    final leadingCharacter = initialsSource.isNotEmpty
        ? initialsSource.characters.first.toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
      child: Column(
        children: [
          _ProfileAvatar(
            imageUrl: imageUrl,
            fallbackText: leadingCharacter,
          ),
          const SizedBox(height: 14),
          Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (username.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '@$username',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Text(
                bio,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String imageUrl;
  final String fallbackText;

  const _ProfileAvatar({
    required this.imageUrl,
    required this.fallbackText,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (imageUrl.isEmpty) {
      return CircleAvatar(
        radius: 38,
        backgroundColor: colorScheme.primaryContainer,
        child: Text(
          fallbackText,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
      );
    }

    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primaryContainer,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          return Center(
            child: Text(
              fallbackText,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          );
        },
      ),
    );
  }
}