import 'package:flutter/material.dart';

import '../../../../shared/public_profile/models/public_profile_event.dart';

class PublicProfileEventList extends StatelessWidget {
  final List<PublicProfileEvent> events;
  final ValueChanged<int> onEventTap;

  const PublicProfileEventList({
    super.key,
    required this.events,
    required this.onEventTap,
  });

  Color _segmentColor(PublicProfileEvent item) {
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

  String _formatPrice(double price) {
    if (price <= 0) return 'Free';
    if (price % 1 == 0) return '${price.toInt()}\$';
    return '${price.toStringAsFixed(2)}\$';
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '';
    final local = value.toLocal();
    return '${local.day}.${local.month}.${local.year}.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SliverList.separated(
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = events[index];

        final subtitleParts = [
          if ((item.segmentName ?? '').trim().isNotEmpty) item.segmentName!.trim(),
          if ((item.genreName ?? '').trim().isNotEmpty) item.genreName!.trim(),
          if ((item.subGenreName ?? '').trim().isNotEmpty) item.subGenreName!.trim(),
        ];
        final subtitle = subtitleParts.join(' · ');

        final accent = _segmentColor(item);
        final imageUrl = item.primaryImage;

        final infoParts = [
          if ((item.locationLabel ?? '').trim().isNotEmpty)
            item.locationLabel!.trim(),
          if (item.startDateTime != null) _formatDate(item.startDateTime),
        ];
        final infoText = infoParts.join(' · ');

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => onEventTap(item.eventId),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B2028) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2A303A)
                        : const Color(0xFFE3EAF3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                      ),
                      child: SizedBox(
                        width: 82,
                        height: 96,
                        child: imageUrl != null && imageUrl.trim().isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return _FallbackImage(accent: accent);
                                },
                              )
                            : _FallbackImage(accent: accent),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        child: Column(
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
                            if (subtitle.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
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
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                            const SizedBox(height: 7),
                            Row(
                              children: [
                                Icon(
                                  Icons.favorite_border_rounded,
                                  size: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  item.likesCount.toString(),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Icon(
                                  Icons.remove_red_eye_outlined,
                                  size: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  item.viewCount.toString(),
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
                      padding: const EdgeInsets.fromLTRB(0, 10, 12, 10),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : const Color(0xFFF3F6FA),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            _formatPrice(item.price),
                            style: theme.textTheme.bodySmall?.copyWith(
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
        );
      },
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