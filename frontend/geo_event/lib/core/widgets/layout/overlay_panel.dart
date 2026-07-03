import 'package:flutter/material.dart';

import 'app_bottom_sheet_container.dart';

class OverlayPanel extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback onClose;
  final double maxHeightFactor;

  const OverlayPanel({
    super.key,
    required this.title,
    required this.child,
    required this.onClose,
    this.maxHeightFactor = 0.62,
  });

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetContainer(
      maxHeightFactor: maxHeightFactor,
      header: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
          ),
          const Divider(height: 1),
        ],
      ),
      child: child,
    );
  }
}