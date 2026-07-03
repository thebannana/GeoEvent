import 'package:flutter/material.dart';

import '../../../../core/widgets/feedback/app_spinner.dart';
import 'map_action_card.dart';

class DirectionsActionCard extends StatelessWidget {
  final String title;
  final bool isLoading;
  final VoidCallback onStartDirections;
  final VoidCallback onReturnToEventDetails;
  final VoidCallback onClose;

  const DirectionsActionCard({
    super.key,
    required this.title,
    required this.onStartDirections,
    required this.onReturnToEventDetails,
    required this.onClose,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MapActionCard(
      title: title,
      leadingIcon: Icons.navigation_rounded,
      onClose: onClose,
      primaryAction: FilledButton(
        onPressed: isLoading ? null : onStartDirections,
        child: isLoading
            ? AppSpinner(
                size: 18,
                strokeWidth: 2.2,
                color: scheme.onPrimary,
              )
            : const Text('Start directions'),
      ),
      secondaryAction: OutlinedButton(
        onPressed: onReturnToEventDetails,
        child: const Text('Return to event details'),
      ),
    );
  }
}