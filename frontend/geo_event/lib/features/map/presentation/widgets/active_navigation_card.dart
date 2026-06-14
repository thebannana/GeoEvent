import 'package:flutter/material.dart';

import '../../../../core/widgets/app_bottom_sheet_container.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                Icons.navigation_rounded,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
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
            child: FilledButton.tonal(
              onPressed: onStopNavigation,
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.errorContainer,
                foregroundColor: colorScheme.onErrorContainer,
              ),
              child: const Text('Stop navigation'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: onViewEventDetails,
              child: const Text('View event details'),
            ),
          ),
        ],
      ),
    );
  }
}