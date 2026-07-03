import 'package:flutter/material.dart';

import '../../../../shared/chat/models/chat_event_info.dart';

class EventChatInfoCard extends StatelessWidget {
  final ChatEventInfo info;
  final VoidCallback onClose;
  final VoidCallback onOpenEvent;

  const EventChatInfoCard({
    super.key,
    required this.info,
    required this.onClose,
    required this.onOpenEvent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final subtitleParts = <String>[
      if (info.startsAt != null) _formatDate(info.startsAt!),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ImageThumb(imageUrl: info.imageUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    height: 1.25,
                  ),
                ),
                if (subtitleParts.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitleParts.join(' • '),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                TextButton(
                  onPressed: onOpenEvent,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('View event details'),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime value) {
    final local = value.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')} $h:$m';
  }
}

class _ImageThumb extends StatelessWidget {
  final String? imageUrl;

  const _ImageThumb({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 64,
        height: 64,
        color: colorScheme.primary.withValues(alpha: 0.10),
        child: hasImage
            ? Image.network(
                imageUrl!.trim(),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(
                  Icons.event_rounded,
                  color: colorScheme.primary,
                ),
              )
            : Icon(
                Icons.event_rounded,
                color: colorScheme.primary,
              ),
      ),
    );
  }
}