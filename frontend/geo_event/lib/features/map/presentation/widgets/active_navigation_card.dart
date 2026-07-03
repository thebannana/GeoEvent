import 'package:flutter/material.dart';

import 'map_action_card.dart';

class ActiveNavigationCard extends StatelessWidget {
  final String title;
  final VoidCallback onStopNavigation;
  final VoidCallback onViewEventDetails;
  final VoidCallback onClose;

  const ActiveNavigationCard({
    super.key,
    required this.title,
    required this.onStopNavigation,
    required this.onViewEventDetails,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MapActionCard(
      title: title,
      leadingIcon: Icons.navigation_rounded,
      onClose: onClose,
      primaryAction: FilledButton.tonal(
        onPressed: onStopNavigation,
        style: FilledButton.styleFrom(
          backgroundColor: scheme.errorContainer,
          foregroundColor: scheme.onErrorContainer,
        ),
        child: const Text('Stop navigation'),
      ),
      secondaryAction: OutlinedButton(
        onPressed: onViewEventDetails,
        child: const Text('View event details'),
      ),
    );
  }
}