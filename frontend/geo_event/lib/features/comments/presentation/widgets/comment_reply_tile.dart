import 'package:flutter/material.dart';

import '../../../../core/utils/date_time_extensions.dart';
import '../../../../shared/comments/models/comment_item.dart';
import 'comment_avatar.dart';
import 'comment_bubble.dart';
import 'comment_meta.dart';

class CommentReplyTile extends StatelessWidget {
  final CommentItem reply;
  final int? currentUserId;
  final ValueChanged<CommentItem> onLikeTap;
  final ValueChanged<CommentItem> onReplyTap;
  final ValueChanged<CommentItem> onEditTap;
  final ValueChanged<CommentItem> onDeleteTap;
  final ValueChanged<CommentItem> onReportTap;

  const CommentReplyTile({
    super.key,
    required this.reply,
    required this.currentUserId,
    required this.onLikeTap,
    required this.onReplyTap,
    required this.onEditTap,
    required this.onDeleteTap,
    required this.onReportTap,
  });

  @override
  Widget build(BuildContext context) {
    final canManage = currentUserId != null &&
        reply.userId != null &&
        currentUserId == reply.userId;

    final colorScheme = Theme.of(context).colorScheme;
    final likedColor = colorScheme.error;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommentAvatar(
          size: 30,
          avatarUrl: reply.avatarUrl,
          fallbackText: commentAuthorName(reply),
          fontSize: 11,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommentBubble(comment: reply, isReply: true),
              const SizedBox(height: 5),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  CommentMetaText(reply.createdAt.timeAgo(short: true)),
                  CommentActionTextButton(
                    label: reply.isLiked ? 'Unlike' : 'Like',
                    color: reply.isLiked ? likedColor : colorScheme.onSurfaceVariant,
                    onTap: reply.isDeleted ? null : () => onLikeTap(reply),
                    disabledReason: 'Deleted replies cannot be liked.',
                  ),
                  CommentActionTextButton(
                    label: 'Reply',
                    onTap: reply.isDeleted ? null : () => onReplyTap(reply),
                    disabledReason: 'Deleted replies cannot be replied to.',
                  ),
                  if (!canManage)
                    CommentActionTextButton(
                      label: 'Report',
                      color: Colors.orangeAccent,
                      onTap: reply.isDeleted ? null : () => onReportTap(reply),
                      disabledReason: 'Deleted replies cannot be reported.',
                    ),
                  if (canManage)
                    CommentActionTextButton(
                      label: 'Edit',
                      onTap: reply.isDeleted ? null : () => onEditTap(reply),
                    ),
                  if (canManage)
                    CommentActionTextButton(
                      label: 'Delete',
                      color: colorScheme.error,
                      onTap: reply.isDeleted ? null : () => onDeleteTap(reply),
                    ),
                  if (reply.likesCount > 0)
                    CommentMetaText(
                      '${reply.likesCount} like${reply.likesCount == 1 ? '' : 's'}',
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        IconButton(
          tooltip: reply.isDeleted
              ? 'Deleted replies cannot be liked'
              : reply.isLiked
                  ? 'Unlike reply'
                  : 'Like reply',
          onPressed: reply.isDeleted ? null : () => onLikeTap(reply),
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.only(top: 2),
          constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
          icon: Icon(
            reply.isLiked ? Icons.favorite : Icons.favorite_border,
            size: 16,
            color: reply.isLiked ? likedColor : colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}