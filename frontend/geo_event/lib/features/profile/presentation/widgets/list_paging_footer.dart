import 'package:flutter/material.dart';

import '../../../../core/widgets/feedback/app_spinner.dart';

class ListPagingFooter extends StatelessWidget {
  const ListPagingFooter({
    super.key,
    required this.isLoadingMore,
    required this.hasMore,
    required this.loadedCount,
    required this.totalCount,
    this.onLoadMore,
    this.itemLabel = 'items',
  });

  final bool isLoadingMore;
  final bool hasMore;
  final int loadedCount;
  final int totalCount;
  final VoidCallback? onLoadMore;
  final String itemLabel;

  @override
  Widget build(BuildContext context) {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: AppSpinner(size: 22, strokeWidth: 2),
        ),
      );
    }

    if (hasMore) {
      return Center(
        child: OutlinedButton.icon(
          onPressed: onLoadMore,
          icon: const Icon(Icons.expand_more_rounded),
          label: Text(
            totalCount > 0
                ? 'Load more ($loadedCount/$totalCount)'
                : 'Load more',
          ),
        ),
      );
    }

    if (loadedCount == 0) {
      return const SizedBox.shrink();
    }

    return Center(
      child: Text(
        'Showing all $loadedCount $itemLabel',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
