import 'package:flutter/material.dart';

import '../../../../core/utils/date_time_extensions.dart';
import '../../../../core/widgets/feedback/app_spinner.dart';
import '../../../../core/widgets/surfaces/app_surface_card.dart';
import '../../../../shared/bookmarks/models/bookmark.dart';
import '../../../../shared/likes/models/liked_event.dart';

class SavedEventCard extends StatelessWidget {
  const SavedEventCard({
    super.key,
    required this.item,
    required this.disabled,
    required this.onTap,
    required this.onDelete,
  });

  final Bookmark item;
  final bool disabled;
  final VoidCallback? onTap;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final subtitle = item.memo?.trim().isNotEmpty == true
        ? item.memo!.trim()
        : 'Saved on ${item.savedAt.formatDate(pattern: 'dd.MM.yyyy')}';

    return BookmarkEventCard(
      title: item.title,
      subtitle: subtitle,
      imageUrl: item.imageUrl,
      icon: Icons.bookmark_rounded,
      accentColor: Theme.of(context).colorScheme.primary,
      removeLabel: 'Remove',
      helperText: 'Tap to open event details',
      disabled: disabled,
      onTap: onTap,
      onDelete: onDelete,
    );
  }
}

class LikedEventCard extends StatelessWidget {
  const LikedEventCard({
    super.key,
    required this.item,
    required this.disabled,
    required this.onTap,
    required this.onDelete,
  });

  final LikedEvent item;
  final bool disabled;
  final VoidCallback? onTap;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return BookmarkEventCard(
      title: item.title,
      subtitle: 'Liked on ${item.likedAt.formatDate(pattern: 'dd.MM.yyyy')}',
      imageUrl: item.imageUrl,
      icon: Icons.favorite_rounded,
      accentColor: Theme.of(context).colorScheme.error,
      removeLabel: 'Unlike',
      helperText: 'Open event details',
      disabled: disabled,
      onTap: onTap,
      onDelete: onDelete,
    );
  }
}

class BookmarkEventCard extends StatelessWidget {
  const BookmarkEventCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.icon,
    required this.accentColor,
    required this.removeLabel,
    required this.helperText,
    required this.disabled,
    required this.onTap,
    required this.onDelete,
  });

  final String title;
  final String subtitle;
  final String? imageUrl;
  final IconData icon;
  final Color accentColor;
  final String removeLabel;
  final String helperText;
  final bool disabled;
  final VoidCallback? onTap;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Opacity(
      opacity: disabled ? 0.72 : 1,
      child: AppSurfaceCard(
        onTap: disabled ? null : onTap,
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookmarkEventCardImage(imageUrl: imageUrl),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 92,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title.trim().isNotEmpty ? title.trim() : 'Saved event',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          enabled: !disabled,
                          tooltip: 'More actions',
                          onSelected: (value) async {
                            if (value == 'delete') {
                              await onDelete();
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(removeLabel),
                                ],
                              ),
                            ),
                          ],
                          icon: Icon(
                            Icons.more_horiz_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          icon,
                          size: 16,
                          color: accentColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            helperText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: accentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BookmarkEventCardImage extends StatelessWidget {
  const BookmarkEventCardImage({
    super.key,
    required this.imageUrl,
  });

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = imageUrl?.trim();
    final hasImage = normalizedUrl != null && normalizedUrl.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 98,
        height: 92,
        child: hasImage
            ? Image.network(
                normalizedUrl,
                fit: BoxFit.cover,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded || frame != null) {
                    return child;
                  }
                  return const _BookmarkEventCardImageFallback(loading: true);
                },
                errorBuilder: (_, _, _) =>
                    const _BookmarkEventCardImageFallback(),
              )
            : const _BookmarkEventCardImageFallback(),
      ),
    );
  }
}

class _BookmarkEventCardImageFallback extends StatelessWidget {
  const _BookmarkEventCardImageFallback({this.loading = false});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: loading
            ? const AppSpinner(size: 22, strokeWidth: 2)
            : Icon(
                Icons.image_not_supported_outlined,
                size: 28,
                color: theme.colorScheme.onSurfaceVariant,
              ),
      ),
    );
  }
}
