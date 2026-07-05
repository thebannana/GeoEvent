import 'package:flutter/material.dart';

import '../../../../shared/comments/models/comment_item.dart';
import 'comment_meta.dart';

class CommentBubble extends StatelessWidget {
  final CommentItem comment;
  final bool isReply;

  const CommentBubble({
    super.key,
    required this.comment,
    required this.isReply,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authorName = commentAuthorName(comment);
    final handle = commentAuthorHandle(comment);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isReply ? 12 : 13,
        vertical: isReply ? 9 : 10,
      ),
      decoration: BoxDecoration(
        color: isReply
            ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.55)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(isReply ? 16 : 18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!comment.isDeleted)
            Wrap(
              spacing: 6,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  authorName,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                if (handle.isNotEmpty)
                  Text(
                    handle,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
              ],
            )
          else
            Text(
              'Deleted user',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          const SizedBox(height: 3),
          Text(
            comment.content,
            style: TextStyle(
              color: comment.isDeleted
                  ? colorScheme.onSurfaceVariant.withValues(alpha: 0.7)
                  : colorScheme.onSurface.withValues(alpha: 0.82),
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}