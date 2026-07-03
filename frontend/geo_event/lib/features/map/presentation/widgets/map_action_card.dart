import 'package:flutter/material.dart';

import '../../../../core/widgets/layout/app_bottom_sheet_container.dart';

class MapActionCard extends StatelessWidget {
  final String title;
  final IconData leadingIcon;
  final Widget primaryAction;
  final Widget secondaryAction;
  final VoidCallback onClose;

  const MapActionCard({
    super.key,
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
                tooltip: 'Close',
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