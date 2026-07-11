import 'package:flutter/material.dart';

import '../../../../core/widgets/surfaces/app_surface_card.dart';

class EventReservationsHeaderCard extends StatelessWidget {
  const EventReservationsHeaderCard({
    super.key,
    required this.eventTitle,
    required this.attendeeCount,
    required this.totalTickets,
    required this.totalReservations,
  });

  final String eventTitle;
  final int attendeeCount;
  final int totalTickets;
  final int totalReservations;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eventTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            [
              _countLabel(attendeeCount, singular: 'attendee'),
              _countLabel(totalTickets, singular: 'ticket'),
              '$totalReservations total reservations',
            ].join(' • '),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  static String _countLabel(
    int count, {
    required String singular,
    String? plural,
  }) {
    final resolvedPlural = plural ?? '${singular}s';
    final label = count == 1 ? singular : resolvedPlural;
    return '$count $label';
  }
}