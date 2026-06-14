import 'package:flutter/material.dart';

import '../../../../core/widgets/app_bottom_sheet_container.dart';
import '../../../../core/widgets/app_spinner.dart';

class _MapActionCard extends StatelessWidget {
  final String title;
  final IconData leadingIcon;
  final Widget primaryAction;
  final Widget secondaryAction;
  final VoidCallback onClose;

  const _MapActionCard({
    required this.title,
    required this.leadingIcon,
    required this.primaryAction,
    required this.secondaryAction,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppBottomSheetContainer(
      scrollable: false,
      showHandle: false,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                leadingIcon,
                color: scheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: primaryAction,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: secondaryAction,
          ),
        ],
      ),
    );
  }
}

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

    return _MapActionCard(
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
    final colorScheme = Theme.of(context).colorScheme;

    return _MapActionCard(
      title: title,
      leadingIcon: Icons.navigation_rounded,
      onClose: onClose,
      primaryAction: FilledButton.tonal(
        onPressed: onStopNavigation,
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.errorContainer,
          foregroundColor: colorScheme.onErrorContainer,
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