import 'package:flutter/material.dart';

import '../../../../core/widgets/feedback/app_empty_state.dart';
import '../../../../core/widgets/feedback/app_spinner.dart';
import '../../../../shared/comments/models/comment_item.dart';
import 'comment_thread_tile.dart';

class CommentThreadList extends StatelessWidget {
  final dynamic state;
  final int? currentUserId;
  final VoidCallback onRefresh;
  final VoidCallback onLoadMore;
  final ValueChanged<CommentItem> onLikeTap;
  final ValueChanged<CommentItem> onReplyTap;
  final ValueChanged<CommentItem> onEditTap;
  final ValueChanged<CommentItem> onDeleteTap;
  final ValueChanged<CommentItem> onReportTap;
  final ValueChanged<int> onLoadRepliesTap;
  final ValueChanged<int> onLoadMoreRepliesTap;

  const CommentThreadList({
    super.key,
    required this.state,
    required this.currentUserId,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onLikeTap,
    required this.onReplyTap,
    required this.onEditTap,
    required this.onDeleteTap,
    required this.onReportTap,
    required this.onLoadRepliesTap,
    required this.onLoadMoreRepliesTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: AppSpinner(size: 24, strokeWidth: 2.5),
        ),
      );
    }

    if (state.comments.isEmpty) {
      return const AppEmptyState(
        title: 'No comments yet',
        message: 'Start the conversation.',
        icon: Icons.chat_bubble_outline_rounded,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      );
    }

    return Column(
      children: [
        ...state.comments.map<Widget>(
          (comment) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: CommentThreadTile(
              comment: comment,
              currentUserId: currentUserId,
              onLikeTap: (c) => onLikeTap(c),
              onReplyTap: onReplyTap,
              onEditTap: onEditTap,
              onDeleteTap: onDeleteTap,
              onReportTap: onReportTap,
              onLoadRepliesTap: (c) => onLoadRepliesTap(c.commentId),
              onLoadMoreRepliesTap: (c) => onLoadMoreRepliesTap(c.commentId),
            ),
          ),
        ),
        if (state.isLoadingMore)
          const Padding(
            padding: EdgeInsets.only(top: 4, bottom: 12),
            child: AppSpinner(size: 20, strokeWidth: 2.2),
          )
        else if (state.hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 12),
            child: TextButton(
              onPressed: onLoadMore,
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                'Load more comments (${state.comments.length}/${state.totalCount})',
              ),
            ),
          ),
        const SizedBox(height: 2),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              TextButton.icon(
                onPressed: state.isLoading ? null : onRefresh,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Refresh comments'),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onSurfaceVariant,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
              if (!state.isLoading && state.totalCount > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Text(
                    '${state.comments.length} of ${state.totalCount}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}