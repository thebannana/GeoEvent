import 'package:flutter/material.dart';
import 'event_meta_row.dart';

class EventInfoSection extends StatelessWidget {
  final String? location;
  final String dateText;
  final String timeText;
  final String countdownText;
  final String description;
  final int capacity;
  final bool isOnline;
  final int? participantCount;
  final String? tags;
  final String? accessibilityInfo;
  final VoidCallback? onDirectionsTap;

  const EventInfoSection({
    super.key,
    required this.location,
    required this.dateText,
    required this.timeText,
    required this.countdownText,
    required this.description,
    required this.capacity,
    required this.isOnline,
    this.participantCount,
    this.tags,
    this.accessibilityInfo,
    this.onDirectionsTap,
  });

  @override
  Widget build(BuildContext context) {
    final capacityText = participantCount != null
        ? '$participantCount / $capacity going'
        : isOnline
            ? 'Online event'
            : 'Capacity: $capacity people';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (location != null && location!.trim().isNotEmpty) ...[
          EventMetaRow(
            icon: Icons.public,
            text: location!,
            onTap: onDirectionsTap,
          ),
          const SizedBox(height: 10),
        ],
        EventMetaRow(
          icon: Icons.calendar_today_outlined,
          text: dateText,
        ),
        const SizedBox(height: 10),
        EventMetaRow(
          icon: Icons.schedule,
          text: timeText,
        ),
        const SizedBox(height: 10),
        EventMetaRow(
          icon: Icons.access_time,
          text: countdownText,
        ),
        const SizedBox(height: 10),
        EventMetaRow(
          icon: isOnline ? Icons.wifi : Icons.groups_2_outlined,
          text: capacityText,
        ),
        if (accessibilityInfo != null && accessibilityInfo!.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          EventMetaRow(
            icon: Icons.accessible_forward,
            text: accessibilityInfo!,
          ),
        ],
        const SizedBox(height: 18),
        const Text(
          'Description',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: const TextStyle(
            color: Colors.white70,
            height: 1.55,
            fontSize: 14,
          ),
        ),
        if (tags != null && tags!.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Tags',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags!
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}