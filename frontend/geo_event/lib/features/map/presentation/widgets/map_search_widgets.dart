import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/location_helpers.dart';
import '../../../../core/widgets/feedback/app_empty_state.dart';
import '../../../../core/widgets/feedback/app_error_state.dart';
import '../../../../core/widgets/feedback/app_loading_indicator.dart';
import '../../../../core/widgets/inputs/app_chip.dart';
import '../../../../core/widgets/surfaces/app_surface_card.dart';
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
      message: 'Looking for events based on your current map search.',
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
          ? 'Try another term, switch to global, or widen your search radius.'
          : showGlobalEvents
              ? 'There are no global events to show right now.'
              : 'Try increasing your distance or enabling global results.',
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
  final double userLatitude;
  final double userLongitude;
  final VoidCallback? onTap;

  const MapSearchEventCard({
    super.key,
    required this.item,
    required this.userLatitude,
    required this.userLongitude,
    this.onTap,
  });

  Color get _accentColor {
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

  String get _priceLabel {
    if (item.price <= 0) return 'Free';
    if (item.price % 1 == 0) return '\$${item.price.toInt()}';
    return '\$${item.price.toStringAsFixed(2)}';
  }

String _distanceLabel() {
  final value = LocationHelpers.distanceKm(
    lat1: userLatitude,
    lon1: userLongitude,
    lat2: item.latitude,
    lon2: item.longitude,
  );

  if (value < 1) {
    return '${(value * 1000).round()} m away';
  }

  return '${value.toStringAsFixed(
    value < 10 ? 1 : 0,
  )} km away';
}

  String get _subtitle {
    final parts = <String>[
      if ((item.promoterName ?? '').isNotEmpty) item.promoterName!,
      if ((item.genreName ?? '').isNotEmpty) item.genreName!,
    ];
    return parts.join(' · ');
  }

  String? get _imageUrl {
    final cover = item.coverImageUrl?.trim();
    if (cover != null && cover.isNotEmpty) {
      return cover;
    }

    for (final url in item.imageUrls) {
      final trimmed = url.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _accentColor;

    return AppSurfaceCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      onTap: onTap,
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
                  height: 104,
                  child: _imageUrl == null
                      ? _fallback(accent)
                      : CachedNetworkImage(
                          imageUrl: _imageUrl!,
                          fit: BoxFit.cover,
                          fadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero,
                          errorWidget: (_, _, _) => _fallback(accent),
                          placeholder: (_, _) => _fallback(accent),
                        ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.segmentName ?? 'Event',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _subtitle.isEmpty ? 'Event discovery result' : _subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _MetaItem(
                            icon: Icons.place_outlined,
                            label: _distanceLabel(),
                          ),
                          _MetaItem(
                            icon: Icons.favorite_border_rounded,
                            label: '${item.likesCount} likes',
                          ),
                          _MetaItem(
                            icon: Icons.remove_red_eye_outlined,
                            label: '${item.viewCount} views',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _priceLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 42),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
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

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}