import 'package:flutter/material.dart';

import '../../../../core/utils/date_time_extensions.dart';
import '../../../../shared/comments/models/comment_item.dart';
import 'comment_avatar.dart';
import 'comment_bubble.dart';
import 'comment_meta.dart';
import 'comment_reply_tile.dart';

class CommentThreadTile extends StatelessWidget {
  final CommentItem comment;
  final int? currentUserId;
  final ValueChanged<CommentItem> onLikeTap;
  final ValueChanged<CommentItem> onReplyTap;
  final ValueChanged<CommentItem> onEditTap;
  final ValueChanged<CommentItem> onDeleteTap;
  final ValueChanged<CommentItem> onReportTap;
  final ValueChanged<CommentItem> onLoadRepliesTap;
  final ValueChanged<CommentItem> onLoadMoreRepliesTap;

  const CommentThreadTile({
    super.key,
    required this.comment,
    required this.currentUserId,
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
    final canManage = currentUserId != null &&
        comment.userId != null &&
        currentUserId == comment.userId;

    final colorScheme = Theme.of(context).colorScheme;
    final likedColor = colorScheme.error;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommentAvatar(
          size: 36,
          avatarUrl: comment.avatarUrl,
          fallbackText: commentAuthorName(comment),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommentBubble(comment: comment, isReply: false),
              const SizedBox(height: 6),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  CommentMetaText(comment.createdAt.timeAgo(short: true)),
                  CommentActionTextButton(
                    label: comment.isLiked ? 'Unlike' : 'Like',
                    color: comment.isLiked ? likedColor : colorScheme.onSurfaceVariant,
                    onTap: comment.isDeleted ? null : () => onLikeTap(comment),
                    disabledReason: 'Deleted comments cannot be liked.',
                  ),
                  CommentActionTextButton(
                    label: 'Reply',
                    onTap: comment.isDeleted ? null : () => onReplyTap(comment),
                    disabledReason: 'Deleted comments cannot be replied to.',
                  ),
                  if (!canManage)
                    CommentActionTextButton(
                      label: 'Report',
                      color: Colors.orangeAccent,
                      onTap: comment.isDeleted ? null : () => onReportTap(comment),
                      disabledReason: 'Deleted comments cannot be reported.',
                    ),
                  if (canManage)
                    CommentActionTextButton(
                      label: 'Edit',
                      onTap: comment.isDeleted ? null : () => onEditTap(comment),
                    ),
                  if (canManage)
                    CommentActionTextButton(
                      label: 'Delete',
                      color: colorScheme.error,
                      onTap: comment.isDeleted ? null : () => onDeleteTap(comment),
                    ),
                  if (comment.likesCount > 0)
                    CommentMetaText(
                      '${comment.likesCount} like${comment.likesCount == 1 ? '' : 's'}',
                    ),
                ],
              ),
              if (comment.replyCount > 0 && !comment.areRepliesLoaded) ...[
                const SizedBox(height: 8),
                CommentActionTextButton(
                  label: comment.isReplyLoading
                      ? 'Loading replies...'
                      : 'View ${comment.replyCount} repl${comment.replyCount == 1 ? 'y' : 'ies'}',
                  color: colorScheme.onSurfaceVariant,
                  onTap: comment.isReplyLoading ? null : () => onLoadRepliesTap(comment),
                ),
              ],
              if (comment.replies.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  margin: const EdgeInsets.only(left: 4),
                  padding: const EdgeInsets.only(left: 14),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.22),
                        width: 1.2,
                      ),
                    ),
                  ),
                  child: Column(
                    children: comment.replies
                        .map(
                          (reply) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: CommentReplyTile(
                              reply: reply,
                              currentUserId: currentUserId,
                              onLikeTap: onLikeTap,
                              onReplyTap: onReplyTap,
                              onEditTap: onEditTap,
                              onDeleteTap: onDeleteTap,
                              onReportTap: onReportTap,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
              if (comment.areRepliesLoaded && comment.hasMoreReplies) ...[
                const SizedBox(height: 8),
                CommentActionTextButton(
                  label: comment.isLoadingMoreReplies
                      ? 'Loading more replies...'
                      : 'Load more replies',
                  color: colorScheme.onSurfaceVariant,
                  onTap: comment.isLoadingMoreReplies
                      ? null
                      : () => onLoadMoreRepliesTap(comment),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: comment.isDeleted
              ? 'Deleted comments cannot be liked'
              : comment.isLiked
                  ? 'Unlike comment'
                  : 'Like comment',
          onPressed: comment.isDeleted ? null : () => onLikeTap(comment),
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.only(top: 2),
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          icon: Icon(
            comment.isLiked ? Icons.favorite : Icons.favorite_border,
            size: 18,
            color: comment.isLiked ? likedColor : colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}