import 'package:flutter/material.dart';

import '../../../../core/widgets/surfaces/app_surface_card.dart';

class AttendeePreviewUser {
  final int userId;
  final String label;
  final String? avatarUrl;

  const AttendeePreviewUser({
    required this.userId,
    required this.label,
    this.avatarUrl,
  });
}

class EventCapacityCard extends StatelessWidget {
  final int capacity;
  final int reservedCount;
  final int attendeeCount;
  final List<AttendeePreviewUser> previewUsers;
  final VoidCallback? onViewAttendeesTap;

  const EventCapacityCard({
    super.key,
    required this.capacity,
    required this.reservedCount,
    required this.attendeeCount,
    this.previewUsers = const [],
    this.onViewAttendeesTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;

    final safeCapacity = capacity <= 0 ? 1 : capacity;
    final normalizedReserved = reservedCount.clamp(0, safeCapacity);
    final progress = (normalizedReserved / safeCapacity).clamp(0.0, 1.0);
    final left = (capacity - normalizedReserved).clamp(0, capacity);

    final muted =
        text.bodyMedium?.color ?? scheme.onSurface.withValues(alpha: 0.72);
    final faint = scheme.onSurface.withValues(alpha: 0.60);

    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups_2_outlined, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Capacity',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Text(
                '$reservedCount / $capacity',
                style: text.bodyMedium?.copyWith(
                  color: muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 0.9 ? scheme.error : scheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                left <= 0 ? 'Sold out' : '$left spots left',
                style: text.bodyMedium?.copyWith(
                  color: left <= 0 ? scheme.error : muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$attendeeCount attendees',
                style: text.bodySmall?.copyWith(
                  color: faint,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (previewUsers.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 34,
              child: Stack(
                children: [
                  for (int i = 0; i < previewUsers.take(5).length; i++)
                    Positioned(
                      left: i * 22,
                      child: _UserAvatar(user: previewUsers[i]),
                    ),
                  if (previewUsers.length > 5)
                    Positioned(
                      left: 5 * 22,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: scheme.surfaceContainerHighest,
                        child: Text(
                          '+${previewUsers.length - 5}',
                          style: text.labelSmall?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onViewAttendeesTap,
              child: const Text('View attendees'),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final AttendeePreviewUser user;

  const _UserAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final avatarUrl = user.avatarUrl?.trim() ?? '';

    return CircleAvatar(
      radius: 16,
      backgroundColor: scheme.outline.withValues(alpha: 0.18),
      child: avatarUrl.isNotEmpty
          ? CircleAvatar(
              radius: 15,
              backgroundImage: NetworkImage(avatarUrl),
            )
          : CircleAvatar(
              radius: 15,
              backgroundColor: scheme.surfaceContainerHighest,
              child: Text(
                _initials(user.label),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
    );
  }

  String _initials(String value) {
    final parts = value
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