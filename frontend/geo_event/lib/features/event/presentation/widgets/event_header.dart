import 'package:flutter/material.dart';

import '../../../../core/widgets/app_icon_circle_button.dart';
import '../../../../core/widgets/app_surface_card.dart';
import 'event_price_badge.dart';

class EventHeader extends StatelessWidget {
  final String title;
  final String? category;
  final String? subCategory;
  final Color? categoryColor;
  final double? ownerRating;
  final String? ownerDisplayName;
  final String? ownerUsername;
  final String? ownerAvatarUrl;
  final int likes;
  final int views;
  final double price;
  final bool isBookmarked;
  final bool isLiked;
  final VoidCallback? onBack;
  final VoidCallback? onReportTap;
  final VoidCallback? onBookmarkTap;
  final VoidCallback? onShareTap;
  final VoidCallback? onOwnerTap;
  final VoidCallback? onLikeTap;

  const EventHeader({
    super.key,
    required this.title,
    required this.likes,
    required this.views,
    required this.price,
    this.category,
    this.subCategory,
    this.categoryColor,
    this.ownerRating,
    this.ownerDisplayName,
    this.ownerUsername,
    this.ownerAvatarUrl,
    this.isBookmarked = false,
    this.isLiked = false,
    this.onBack,
    this.onReportTap,
    this.onBookmarkTap,
    this.onShareTap,
    this.onOwnerTap,
    this.onLikeTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;

    final categoryText = [category, subCategory]
        .where((e) => e != null && e.trim().isNotEmpty)
        .join(' • ');

    final displayName = ownerDisplayName?.trim();
    final username = ownerUsername?.trim();
    final avatarUrl = ownerAvatarUrl?.trim();

    final ownerPrimaryText = (username != null && username.isNotEmpty)
        ? '@$username'
        : (displayName != null && displayName.isNotEmpty ? displayName : null);

    final ownerSecondaryText =
        (displayName != null &&
                displayName.isNotEmpty &&
                username != null &&
                username.isNotEmpty)
            ? displayName
            : null;

    final hasOwner =
        (ownerPrimaryText != null && ownerPrimaryText.isNotEmpty) ||
            (avatarUrl != null && avatarUrl.isNotEmpty);

    final accent = categoryColor ?? scheme.primary;
    final muted = text.bodyMedium?.color ?? scheme.onSurface.withValues(alpha: 0.72);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppIconCircleButton(
              onPressed: onBack,
              tooltip: 'Back',
              icon: Icons.arrow_back_ios_new,
            ),
            const Spacer(),
            AppIconCircleButton(
              onPressed: onLikeTap,
              tooltip: isLiked ? 'Unlike event' : 'Like event',
              icon: isLiked ? Icons.favorite : Icons.favorite_border,
              foregroundColor: isLiked ? scheme.error : null,
            ),
            const SizedBox(width: 8),
            AppIconCircleButton(
              onPressed: onBookmarkTap,
              tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark event',
              icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              foregroundColor: isBookmarked ? scheme.primary : null,
            ),
            const SizedBox(width: 8),
            if (onReportTap != null) ...[
              AppIconCircleButton(
                onPressed: onReportTap,
                tooltip: 'Report event',
                icon: Icons.outlined_flag_rounded,
              ),
              const SizedBox(width: 8),
            ],
            AppIconCircleButton(
              onPressed: onShareTap,
              tooltip: 'Share event',
              icon: Icons.ios_share,
            ),
            const SizedBox(width: 8),
          ],
        ),
        const SizedBox(height: 18),
        if (categoryText.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: accent.withValues(alpha: 0.32)),
            ),
            child: Text(
              categoryText,
              style: text.labelLarge?.copyWith(
                color: accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            EventPriceBadge(price: price),
            Text('$likes likes', style: text.bodyMedium?.copyWith(color: muted)),
            Text('$views views', style: text.bodyMedium?.copyWith(color: muted)),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: text.headlineSmall?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        if (hasOwner) ...[
          const SizedBox(height: 14),
          AppSurfaceCard(
            onTap: onOwnerTap,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _OwnerAvatar(
                  avatarUrl: avatarUrl,
                  fallbackText: ownerSecondaryText ?? ownerPrimaryText ?? 'U',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ownerPrimaryText ?? 'Organizer',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.titleMedium?.copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (ownerRating != null) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${ownerRating!.toStringAsFixed(1)}/5',
                              style: text.bodySmall?.copyWith(
                                color: muted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (ownerSecondaryText != null &&
                          ownerSecondaryText.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          ownerSecondaryText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(
                            color: muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: scheme.onSurface.withValues(alpha: 0.54),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _OwnerAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String fallbackText;

  const _OwnerAvatar({
    required this.avatarUrl,
    required this.fallbackText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final trimmed = avatarUrl?.trim() ?? '';

    if (trimmed.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: scheme.surfaceContainerHighest,
        backgroundImage: NetworkImage(trimmed),
        onBackgroundImageError: (_, __) {},
      );
    }

    return CircleAvatar(
      radius: 22,
      backgroundColor: scheme.surfaceContainerHighest,
      child: Text(
        _initials(fallbackText),
        style: theme.textTheme.labelLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _initials(String text) {
    final parts = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}