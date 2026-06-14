import 'package:flutter/material.dart';

import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../../../shared/events/models/create_event_models.dart';

class MapSearchFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isActive;

  const MapSearchFilterChip({
    super.key,
    required this.label,
    this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppChip(
      label: label,
      selected: isActive,
      onTap: onTap,
      icon: Icons.keyboard_arrow_down_rounded,
    );
  }
}

class MapSearchLoadingView extends StatelessWidget {
  const MapSearchLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppLoadingIndicator(
      title: 'Searching',
      message: 'Looking for events near you.',
    );
  }
}

class MapSearchEmptyView extends StatelessWidget {
  final bool hasQuery;
  final bool showGlobalEvents;

  const MapSearchEmptyView({
    super.key,
    required this.hasQuery,
    required this.showGlobalEvents,
  });

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      title: hasQuery
          ? 'No events found'
          : showGlobalEvents
              ? 'No global events found'
              : 'No nearby events found',
      message: hasQuery
          ? 'Try a different search phrase or widen your radius.'
          : showGlobalEvents
              ? 'There are no global events to show right now.'
              : 'Try increasing your distance or turning on global search.',
    );
  }
}

class MapSearchErrorView extends StatelessWidget {
  final String message;

  const MapSearchErrorView({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return AppErrorState(message: message);
  }
}

class MapSearchEventCard extends StatelessWidget {
  final EventItem item;

  const MapSearchEventCard({
    super.key,
    required this.item,
  });

  Color _segmentColor() {
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

  String _formatPrice() {
    if (item.price <= 0) return 'Free';
    if (item.price % 1 == 0) return '${item.price.toInt()}\$';
    return '${item.price.toStringAsFixed(2)}\$';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _segmentColor();

    final subtitleParts = <String>[
      if ((item.promoterName ?? '').isNotEmpty) 'By: ${item.promoterName}',
      if ((item.genreName ?? '').isNotEmpty) item.genreName!,
    ];

    final subtitle = subtitleParts.join(' · ');

    String? imageUrl = item.coverImageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      if (item.imageUrls.isNotEmpty) {
        final first = item.imageUrls.first;
        if (first.isNotEmpty) {
          imageUrl = first;
        }
      }
    }

    return AppSurfaceCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: SizedBox(
                  width: 102,
                  height: 96,
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _fallback(accent),
                        )
                      : _fallback(accent),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.segmentName != null && item.segmentName!.isNotEmpty
                            ? '${item.segmentName}: ${item.title}'
                            : item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle.isEmpty ? 'Event' : subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.favorite_border_rounded,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.likesCount} likes',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            Icons.remove_red_eye_outlined,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.viewCount} views',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.more_horiz_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 36),
                    Text(
                      'Price: ${_formatPrice()}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Container(
            height: 4,
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback(Color accent) {
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