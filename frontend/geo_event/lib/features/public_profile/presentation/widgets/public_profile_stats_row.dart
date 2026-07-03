import 'package:flutter/material.dart';

import '../../../../core/widgets/surfaces/app_surface_card.dart';
import '../../../../shared/public_profile/models/public_profile_user.dart';

class PublicProfileStatsRow extends StatelessWidget {
  final PublicProfileUser user;
  final int eventsCount;

  const PublicProfileStatsRow({
    super.key,
    required this.user,
    required this.eventsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Expanded(
            child: StatItem(
              label: 'Events',
              value: eventsCount.toString(),
            ),
          ),
          Expanded(
            child: StatItem(
              label: 'Ratings',
              value: user.ratingsCount.toString(),
            ),
          ),
          Expanded(
            child: StatItem(
              label: 'Average',
              value: user.ratingsCount == 0
                  ? '—'
                  : user.averageRating.toStringAsFixed(1),
            ),
          ),
        ],
      ),
    );
  }
}

class StatItem extends StatelessWidget {
  final String label;
  final String value;

  const StatItem({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}