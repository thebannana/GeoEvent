import 'package:flutter/material.dart';

import '../../../../shared/comments/models/comment_item.dart';

class InlineErrorBanner extends StatelessWidget {
  final String message;

  const InlineErrorBanner({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message.trim(),
        style: TextStyle(
          color: colorScheme.onErrorContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class CommentActionTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final String? disabledReason;

  const CommentActionTextButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color,
    this.disabledReason,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = color ?? colorScheme.onSurfaceVariant;
    final effectiveColor = onTap == null
        ? colorScheme.onSurface.withValues(alpha: 0.28)
        : baseColor;

    return Tooltip(
      message: onTap == null && disabledReason != null ? disabledReason! : label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          child: Text(
            label,
            style: TextStyle(
              color: effectiveColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class CommentMetaText extends StatelessWidget {
  final String text;

  const CommentMetaText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

String commentAuthorName(CommentItem comment) {
  if (comment.isDeleted) return 'Deleted user';

  final displayName = comment.displayName?.trim();
  if (displayName != null && displayName.isNotEmpty) return displayName;

  final username = comment.username?.trim();
  if (username != null && username.isNotEmpty) {
    return username.replaceFirst(RegExp(r'^@+'), '');
  }

  return 'Unknown user';
}

String commentAuthorHandle(CommentItem comment) {
  if (comment.isDeleted) return '';

  final username = comment.username?.trim();
  if (username == null || username.isEmpty) return '';

  final cleaned = username.replaceFirst(RegExp(r'^@+'), '');
  if (cleaned.isEmpty) return '';

  return '@$cleaned';
}