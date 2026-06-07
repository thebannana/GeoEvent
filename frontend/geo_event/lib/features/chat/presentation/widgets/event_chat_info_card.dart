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
    final subtitleParts = <String>[
      if (info.startsAt != null) _formatDate(info.startsAt!),
      if ((info.venueName ?? '').trim().isNotEmpty) info.venueName!.trim(),
      if ((info.cityName ?? '').trim().isNotEmpty) info.cityName!.trim(),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitleParts.join(' • '),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onOpenEvent,
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
    return '${local.day.toString().padLeft(2, '0')}.'
        '${local.month.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}