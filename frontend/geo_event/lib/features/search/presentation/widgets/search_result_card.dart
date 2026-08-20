import 'package:flutter/material.dart';

import '../../../../core/utils/price_formatter.dart';
import '../../../../shared/events/models/create_event_models.dart';
import '../../../event/presentation/screens/event_detail_screen.dart';

class SearchResultCard extends StatelessWidget {
  final EventItem item;
  final ValueChanged<EventItem>? onOpenDirections;
  final VoidCallback? onCloseParentSearchSheet;
  final String? recommendationLabel;

  const SearchResultCard({
    super.key,
    required this.item,
    this.onOpenDirections,
    this.onCloseParentSearchSheet,
    this.recommendationLabel,
  });

  static Color _segmentColor(EventItem item) {
    final name = (item.segmentName ?? '').toLowerCase();

    if (name.contains('concert') || name.contains('music')) {
      return const Color(0xFF5E7BFF);
    }
    if (name.contains('sport')) {
      return const Color(0xFFFF5A76);
    }
    if (name.contains('education') || name.contains('seminar')) {
      return const Color(0xFF68C95A);
    }
    return const Color(0xFF6B8FBF);
  }

  static String _subtitle(EventItem item) {
    final parts = [
      if ((item.segmentName ?? '').isNotEmpty) item.segmentName!,
      if ((item.genreName ?? '').isNotEmpty) item.genreName!,
      if ((item.subGenreName ?? '').isNotEmpty) item.subGenreName!,
    ];

    return parts.join(' · ');
  }

  static String? _imageUrl(EventItem item) {
    return item.coverImageUrl ??
        (item.imageUrls.isNotEmpty ? item.imageUrls.first : null);
  }

  void _openDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventDetailsScreen(
          eventId: item.eventId,
          onCloseParentSearchSheet: onCloseParentSearchSheet,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = _segmentColor(item);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openDetails(context),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.75),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _SearchResultCardImage(
                  imageUrl: _imageUrl(item),
                  accent: accent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    child: _SearchResultCardContent(
                      item: item,
                      subtitle: _subtitle(item),
                      onOpenDirections: onOpenDirections,
                      accent: accent,
                      recommendationLabel: recommendationLabel,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchResultCardImage extends StatelessWidget {
  final String? imageUrl;
  final Color accent;

  const _SearchResultCardImage({
    required this.imageUrl,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(18),
        bottomLeft: Radius.circular(18),
      ),
      child: SizedBox(
        width: 82,
        height: 96,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) {
                  return _SearchResultImageFallback(accent: accent);
                },
              )
            : _SearchResultImageFallback(accent: accent),
      ),
    );
  }
}

class _SearchResultCardContent extends StatelessWidget {
  final EventItem item;
  final String subtitle;
  final ValueChanged<EventItem>? onOpenDirections;
  final Color accent;
  final String? recommendationLabel;

  const _SearchResultCardContent({
    required this.item,
    required this.subtitle,
    required this.onOpenDirections,
    required this.accent,
    this.recommendationLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (recommendationLabel != null && recommendationLabel!.isNotEmpty) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 15,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  recommendationLabel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 7),
        _SearchResultMetrics(item: item),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    PriceFormatter.formatPriceWithBam(item.price),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Open directions',
              onPressed: onOpenDirections != null
                  ? () => onOpenDirections!(item)
                  : null,
              icon: const Icon(Icons.directions_rounded),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surfaceContainerHighest,
                foregroundColor: accent,
                disabledForegroundColor: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SearchResultMetrics extends StatelessWidget {
  final EventItem item;

  const _SearchResultMetrics({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final style = theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return Row(
      children: [
        Icon(
          Icons.favorite_border_rounded,
          size: 12,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 3),
        Text(
          item.likesCount.toString(),
          style: style,
        ),
        const SizedBox(width: 10),
        Icon(
          Icons.remove_red_eye_outlined,
          size: 12,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 3),
        Text(
          item.viewCount.toString(),
          style: style,
        ),
      ],
    );
  }
}

class _SearchResultImageFallback extends StatelessWidget {
  final Color accent;

  const _SearchResultImageFallback({
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: accent.withValues(alpha: 0.90),
      alignment: Alignment.center,
      child: const Icon(
        Icons.event_rounded,
        size: 30,
        color: Colors.white,
      ),
    );
  }
}