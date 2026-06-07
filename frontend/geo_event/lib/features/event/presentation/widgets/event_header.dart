import 'package:flutter/material.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _CircleAction(icon: Icons.arrow_back_ios_new, onTap: onBack),
            const Spacer(),
            _CircleAction(
              icon: isLiked ? Icons.favorite : Icons.favorite_border,
              onTap: onLikeTap,
            ),
            const SizedBox(width: 8),
            _CircleAction(
              icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              onTap: onBookmarkTap,
            ),
            const SizedBox(width: 8),
            _CircleAction(
              icon: Icons.outlined_flag_rounded,
              onTap: onReportTap,
            ),
            const SizedBox(width: 8),
            _CircleAction(icon: Icons.ios_share, onTap: onShareTap),
          ],
        ),
        const SizedBox(height: 18),
        if (categoryText.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (categoryColor ?? Colors.white).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: (categoryColor ?? Colors.white).withValues(alpha: 0.45),
              ),
            ),
            child: Text(
              categoryText,
              style: TextStyle(
                color: categoryColor ?? Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
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
            Text(
              '$likes likes',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              '$views views',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        if (hasOwner) ...[
          const SizedBox(height: 14),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onOwnerTap,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    _OwnerAvatar(
                      avatarUrl: avatarUrl,
                      fallbackText:
                          ownerSecondaryText ?? ownerPrimaryText ?? 'U',
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
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
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
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
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
                              style: const TextStyle(
                                color: Colors.white60,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.white54,
                    ),
                  ],
                ),
              ),
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
    final trimmed = avatarUrl?.trim() ?? '';

    if (trimmed.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: Colors.white12,
        backgroundImage: NetworkImage(trimmed),
        onBackgroundImageError: (_, __) {},
      );
    }

    return CircleAvatar(
      radius: 22,
      backgroundColor: Colors.white12,
      child: Text(
        _initials(fallbackText),
        style: const TextStyle(
          color: Colors.white,
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
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CircleAction({
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            color: enabled ? Colors.white : Colors.white30,
          ),
        ),
      ),
    );
  }
}