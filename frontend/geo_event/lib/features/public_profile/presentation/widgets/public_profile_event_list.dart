import 'package:flutter/material.dart';

import '../../../../shared/public_profile/models/public_profile_event.dart';

class PublicProfileEventList extends StatelessWidget {
  final List<PublicProfileEvent> events;
  final ValueChanged<int> onEventTap;
  final bool hasNextPage;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;

  const PublicProfileEventList({
    super.key,
    required this.events,
    required this.onEventTap,
    required this.hasNextPage,
    required this.isLoadingMore,
    required this.onLoadMore,
  });

  Color _segmentColor(BuildContext context, PublicProfileEvent item) {
    final scheme = Theme.of(context).colorScheme;
    final name = (item.segmentName ?? '').toLowerCase();

    if (name.contains('concert') || name.contains('music')) {
      return scheme.primary;
    }
    if (name.contains('sport')) {
      return scheme.error;
    }
    if (name.contains('education') || name.contains('seminar')) {
      return scheme.tertiary;
    }
    return scheme.secondary;
  }

  String _formatPrice(double price) {
    if (price <= 0) return 'Free';
    if (price % 1 == 0) return price.toInt().toString();
    return price.toStringAsFixed(2);
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '';
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.'
        '${local.month.toString().padLeft(2, '0')}.'
        '${local.year}.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SliverList(
      delegate: SliverChildListDelegate([
        ...List.generate(events.length, (index) {
          final item = events[index];

          final subtitleParts = <String>[
            if ((item.segmentName ?? '').trim().isNotEmpty)
              item.segmentName!.trim(),
            if ((item.genreName ?? '').trim().isNotEmpty)
              item.genreName!.trim(),
            if ((item.subGenreName ?? '').trim().isNotEmpty)
              item.subGenreName!.trim(),
          ];
          final subtitle = subtitleParts.join(' · ');

          final accent = _segmentColor(context, item);
          final imageUrl = (item.primaryImage ?? '').trim();

          final infoParts = <String>[
            if ((item.resolvedLocationName ?? '').trim().isNotEmpty)
              item.resolvedLocationName!.trim(),
            if (item.startDateTime != null) _formatDate(item.startDateTime),
          ];
          final infoText = infoParts.join(' · ');

          return Padding(
            padding: EdgeInsets.only(bottom: index == events.length - 1 ? 0 : 10),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => onEventTap(item.eventId),
                child: Ink(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.8),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.10 : 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 12, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(18),
                            bottomLeft: Radius.circular(18),
                          ),
                          child: SizedBox(
                            width: 82,
                            height: 110,
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) {
                                      return _FallbackImage(accent: accent);
                                    },
                                  )
                                : _FallbackImage(accent: accent),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
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
                                if (infoText.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    infoText,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    _InlineStat(
                                      icon: Icons.favorite_border_rounded,
                                      value: item.likesCount.toString(),
                                    ),
                                    _InlineStat(
                                      icon: Icons.remove_red_eye_outlined,
                                      value: item.viewCount.toString(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              child: Text(
                                _formatPrice(item.price),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        if (hasNextPage || isLoadingMore)
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 4),
            child: Center(
              child: isLoadingMore
                  ? const CircularProgressIndicator()
                  : OutlinedButton(
                      onPressed: onLoadMore,
                      child: const Text('Load more events'),
                    ),
            ),
          ),
      ]),
    );
  }
}

class _InlineStat extends StatelessWidget {
  final IconData icon;
  final String value;

  const _InlineStat({
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
              ),
        ),
      ],
    );
  }
}

class _FallbackImage extends StatelessWidget {
  final Color accent;

  const _FallbackImage({
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: accent.withValues(alpha: 0.16),
      alignment: Alignment.center,
      child: Icon(
        Icons.event_rounded,
        size: 30,
        color: accent,
      ),
    );
  }
}