import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_time_extensions.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_spinner.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../../../shared/comments/models/comment_item.dart';
import '../../../../shared/reports/models/report_target_type.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../reports/presentation/screens/report_screen.dart';
import '../../application/event_comments_controller.dart';

class InlineEventCommentsSection extends ConsumerStatefulWidget {
  final int eventId;
  final int? currentUserId;

  const InlineEventCommentsSection({
    super.key,
    required this.eventId,
    required this.currentUserId,
  });

  @override
  ConsumerState<InlineEventCommentsSection> createState() =>
      _InlineEventCommentsSectionState();
}

class _InlineEventCommentsSectionState
    extends ConsumerState<InlineEventCommentsSection> {
  final TextEditingController _composerController = TextEditingController();

  @override
  void dispose() {
    _composerController.dispose();
    super.dispose();
  }

  Future<void> _openReportCommentScreen(CommentItem comment) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportScreen(
          targetType: ReportTargetType.comment,
          targetId: comment.commentId,
          targetTitle: commentAuthorName(comment),
          targetSubtitle: comment.content,
          targetImageUrl: comment.avatarUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final state = ref.watch(eventCommentsControllerProvider(widget.eventId));
    final controller =
        ref.read(eventCommentsControllerProvider(widget.eventId).notifier);

    final authState = ref.watch(authStateProvider);
    final currentUser = authState.user;

    final currentUserDisplayName = [
      currentUser?.firstName.trim(),
      currentUser?.lastName.trim(),
    ].where((e) => e != null && e.isNotEmpty).join(' ').trim();

    final effectiveDisplayName = currentUserDisplayName.isNotEmpty
        ? currentUserDisplayName
        : (currentUser?.username.trim().isNotEmpty == true
            ? currentUser!.username.trim()
            : 'You');

    final currentUserAvatarUrl = currentUser?.imageUrl?.trim().isNotEmpty == true
        ? currentUser!.imageUrl!.trim()
        : null;

    final errorText = state.error;
    final isEditing = state.editingCommentId != null;
    final isReplying = state.replyingToCommentId != null;

    return AppSurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comments',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 14),
          if (errorText != null && errorText.trim().isNotEmpty) ...[
            _InlineErrorBanner(message: errorText),
            const SizedBox(height: 12),
          ],
          if (isReplying || isEditing)
            _ComposerStateBanner(
              isEditing: isEditing,
              onCancel: () {
                controller.cancelReply();
                controller.cancelEdit();
                _composerController.clear();
              },
            ),
          _CommentComposer(
            controller: _composerController,
            isEditing: isEditing,
            isReplying: isReplying,
            isSubmitting: state.isSubmitting,
            currentUserAvatarUrl: currentUserAvatarUrl,
            currentUserDisplayName: effectiveDisplayName,
            onSubmit: () async {
              final text = _composerController.text.trim();
              if (text.isEmpty) return;

              final editingId = state.editingCommentId;
              if (editingId != null) {
                await controller.saveEdit(
                  commentId: editingId,
                  rawText: text,
                );
              } else {
                await controller.submitComment(text);
              }

              _composerController.clear();
            },
          ),
          const SizedBox(height: 18),
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: AppSpinner(size: 24, strokeWidth: 2.5),
              ),
            )
          else if (state.comments.isEmpty)
            const AppEmptyState(
              title: 'No comments yet',
              message: 'Start the conversation.',
              icon: Icons.chat_bubble_outline_rounded,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            )
          else
            Column(
              children: state.comments
                  .map(
                    (comment) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _ThreadCommentTile(
                        comment: comment,
                        currentUserId: widget.currentUserId,
                        onLikeTap: comment.isDeleted
                            ? null
                            : () => controller.toggleLike(comment),
                        onReplyTap: comment.isDeleted
                            ? null
                            : () {
                                controller.startReply(comment.commentId);
                                _composerController.clear();
                              },
                        onEditTap: _canManageComment(
                                  currentUserId: widget.currentUserId,
                                  authorUserId: comment.userId,
                                ) &&
                                !comment.isDeleted
                            ? () {
                                controller.startEdit(comment.commentId);
                                _composerController.text = comment.content;
                              }
                            : null,
                        onDeleteTap: _canManageComment(
                                  currentUserId: widget.currentUserId,
                                  authorUserId: comment.userId,
                                ) &&
                                !comment.isDeleted
                            ? () => controller.deleteComment(comment.commentId)
                            : null,
                        onReportTap: _openReportCommentScreen,
                        onLoadRepliesTap: (comment.replyCount > 0 &&
                                !comment.areRepliesLoaded &&
                                !comment.isReplyLoading)
                            ? () => controller.loadReplies(comment.commentId)
                            : null,
                        onReplyLikeTap: (reply) => controller.toggleLike(reply),
                        onReplyReplyTap: (reply) {
                          controller.startReply(reply.commentId);
                          _composerController.clear();
                        },
                        onReplyEditTap: (reply) {
                          controller.startEdit(reply.commentId);
                          _composerController.text = reply.content;
                        },
                        onReplyDeleteTap: (reply) =>
                            controller.deleteComment(reply.commentId),
                        onReplyReportTap: _openReportCommentScreen,
                      ),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: state.isLoading ? null : controller.refresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh comments'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canManageComment({
    required int? currentUserId,
    required int? authorUserId,
  }) {
    if (currentUserId == null || authorUserId == null) return false;
    return currentUserId == authorUserId;
  }
}

class _InlineErrorBanner extends StatelessWidget {
  final String message;

  const _InlineErrorBanner({
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
        message,
        style: TextStyle(
          color: colorScheme.onErrorContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ComposerStateBanner extends StatelessWidget {
  final bool isEditing;
  final VoidCallback onCancel;

  const _ComposerStateBanner({
    required this.isEditing,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            isEditing ? Icons.edit_outlined : Icons.reply_rounded,
            color: colorScheme.onSurfaceVariant,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isEditing ? 'Editing comment' : 'Replying to comment',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class _CommentComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool isEditing;
  final bool isReplying;
  final bool isSubmitting;
  final Future<void> Function() onSubmit;
  final String? currentUserAvatarUrl;
  final String currentUserDisplayName;

  const _CommentComposer({
    required this.controller,
    required this.isEditing,
    required this.isReplying,
    required this.isSubmitting,
    required this.onSubmit,
    required this.currentUserAvatarUrl,
    required this.currentUserDisplayName,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _AvatarBubble(
          size: 36,
          avatarUrl: currentUserAvatarUrl,
          fallbackText: currentUserDisplayName,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.22),
              ),
            ),
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 5,
              style: TextStyle(
                color: colorScheme.onSurface,
                height: 1.3,
              ),
              decoration: InputDecoration(
                hintText: isEditing
                    ? 'Edit your comment...'
                    : isReplying
                        ? 'Write a reply...'
                        : 'Add a comment...',
                hintStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                filled: true,
                fillColor: Colors.transparent,
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        FilledButton(
          onPressed: isSubmitting ? null : onSubmit,
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 42),
            padding: const EdgeInsets.symmetric(horizontal: 14),
          ),
          child: isSubmitting
              ? const AppSpinner(
                  size: 16,
                  strokeWidth: 2,
                  color: Colors.white,
                )
              : Text(isEditing ? 'Save' : 'Post'),
        ),
      ],
    );
  }
}

class _ThreadCommentTile extends StatelessWidget {
  final CommentItem comment;
  final int? currentUserId;
  final VoidCallback? onLikeTap;
  final VoidCallback? onReplyTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;
  final VoidCallback? onLoadRepliesTap;
  final ValueChanged<CommentItem> onReplyLikeTap;
  final ValueChanged<CommentItem> onReplyReplyTap;
  final ValueChanged<CommentItem> onReplyEditTap;
  final ValueChanged<CommentItem> onReplyDeleteTap;
  final ValueChanged<CommentItem>? onReportTap;
  final ValueChanged<CommentItem>? onReplyReportTap;

  const _ThreadCommentTile({
    required this.comment,
    required this.currentUserId,
    required this.onLikeTap,
    required this.onReplyTap,
    required this.onEditTap,
    required this.onDeleteTap,
    required this.onLoadRepliesTap,
    required this.onReplyLikeTap,
    required this.onReplyReplyTap,
    required this.onReplyEditTap,
    required this.onReplyDeleteTap,
    required this.onReportTap,
    required this.onReplyReportTap,
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
        _AvatarBubble(
          size: 36,
          avatarUrl: comment.avatarUrl,
          fallbackText: commentAuthorName(comment),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CommentBubble(
                comment: comment,
                isReply: false,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _MetaText(comment.createdAt.timeAgo(short: true)),
                  _ActionTextButton(
                    label: comment.isLiked ? 'Unlike' : 'Like',
                    color:
                        comment.isLiked ? likedColor : colorScheme.onSurfaceVariant,
                    onTap: comment.isDeleted ? null : onLikeTap,
                  ),
                  _ActionTextButton(
                    label: 'Reply',
                    onTap: comment.isDeleted ? null : onReplyTap,
                  ),
                  if (!canManage && onReportTap != null)
                    _ActionTextButton(
                      label: 'Report',
                      color: Colors.orangeAccent,
                      onTap:
                          comment.isDeleted ? null : () => onReportTap!(comment),
                    ),
                  if (canManage)
                    _ActionTextButton(
                      label: 'Edit',
                      onTap: onEditTap,
                    ),
                  if (canManage)
                    _ActionTextButton(
                      label: 'Delete',
                      color: colorScheme.error,
                      onTap: onDeleteTap,
                    ),
                  if (comment.likesCount > 0)
                    _MetaText(
                      '${comment.likesCount} like${comment.likesCount == 1 ? '' : 's'}',
                    ),
                ],
              ),
              if (comment.replyCount > 0 && !comment.areRepliesLoaded) ...[
                const SizedBox(height: 8),
                _ActionTextButton(
                  label: comment.isReplyLoading
                      ? 'Loading replies...'
                      : 'View ${comment.replyCount} repl${comment.replyCount == 1 ? 'y' : 'ies'}',
                  color: colorScheme.onSurfaceVariant,
                  onTap: onLoadRepliesTap,
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
                            child: _ReplyCommentTile(
                              reply: reply,
                              currentUserId: currentUserId,
                              onLikeTap: reply.isDeleted
                                  ? null
                                  : () => onReplyLikeTap(reply),
                              onReplyTap: reply.isDeleted
                                  ? null
                                  : () => onReplyReplyTap(reply),
                              onEditTap:
                                  _canManage(currentUserId, reply.userId) &&
                                          !reply.isDeleted
                                      ? () => onReplyEditTap(reply)
                                      : null,
                              onDeleteTap:
                                  _canManage(currentUserId, reply.userId) &&
                                          !reply.isDeleted
                                      ? () => onReplyDeleteTap(reply)
                                      : null,
                              onReportTap: onReplyReportTap,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: comment.isLiked ? 'Unlike comment' : 'Like comment',
          onPressed: comment.isDeleted ? null : onLikeTap,
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

  bool _canManage(int? currentUserId, int? authorUserId) {
    if (currentUserId == null || authorUserId == null) return false;
    return currentUserId == authorUserId;
  }
}

class _ReplyCommentTile extends StatelessWidget {
  final CommentItem reply;
  final int? currentUserId;
  final VoidCallback? onLikeTap;
  final VoidCallback? onReplyTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;
  final ValueChanged<CommentItem>? onReportTap;

  const _ReplyCommentTile({
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
        _AvatarBubble(
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
              _CommentBubble(
                comment: reply,
                isReply: true,
              ),
              const SizedBox(height: 5),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _MetaText(reply.createdAt.timeAgo(short: true)),
                  _ActionTextButton(
                    label: reply.isLiked ? 'Unlike' : 'Like',
                    color:
                        reply.isLiked ? likedColor : colorScheme.onSurfaceVariant,
                    onTap: reply.isDeleted ? null : onLikeTap,
                  ),
                  _ActionTextButton(
                    label: 'Reply',
                    onTap: reply.isDeleted ? null : onReplyTap,
                  ),
                  if (!canManage && onReportTap != null)
                    _ActionTextButton(
                      label: 'Report',
                      color: Colors.orangeAccent,
                      onTap: reply.isDeleted ? null : () => onReportTap!(reply),
                    ),
                  if (canManage)
                    _ActionTextButton(
                      label: 'Edit',
                      onTap: onEditTap,
                    ),
                  if (canManage)
                    _ActionTextButton(
                      label: 'Delete',
                      color: colorScheme.error,
                      onTap: onDeleteTap,
                    ),
                  if (reply.likesCount > 0)
                    _MetaText(
                      '${reply.likesCount} like${reply.likesCount == 1 ? '' : 's'}',
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        IconButton(
          tooltip: reply.isLiked ? 'Unlike reply' : 'Like reply',
          onPressed: reply.isDeleted ? null : onLikeTap,
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

class _CommentBubble extends StatelessWidget {
  final CommentItem comment;
  final bool isReply;

  const _CommentBubble({
    required this.comment,
    required this.isReply,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authorName = commentAuthorName(comment);
    final username = commentUsername(comment);

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
                if (username.isNotEmpty)
                  Text(
                    '@$username',
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

class _AvatarBubble extends StatelessWidget {
  final double size;
  final String fallbackText;
  final String? avatarUrl;
  final double fontSize;

  const _AvatarBubble({
    required this.size,
    required this.fallbackText,
    this.avatarUrl,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _buildInitials(fallbackText);
    final colorScheme = Theme.of(context).colorScheme;

    if (avatarUrl != null && avatarUrl!.trim().isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: colorScheme.surfaceContainerHighest,
        backgroundImage: NetworkImage(avatarUrl!),
        onBackgroundImageError: (_, __) {},
      );
    }

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.85),
            colorScheme.secondary.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: colorScheme.onPrimary,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _buildInitials(String text) {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return '?';

    final parts =
        cleaned.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();

    return '${parts.first.characters.first}${parts[1].characters.first}'
        .toUpperCase();
  }
}

class _ActionTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  const _ActionTextButton({
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = color ?? colorScheme.onSurfaceVariant;
    final effectiveColor =
        onTap == null ? colorScheme.onSurface.withValues(alpha: 0.28) : baseColor;

    return InkWell(
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
    );
  }
}

class _MetaText extends StatelessWidget {
  final String text;

  const _MetaText(this.text);

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
  if (username != null && username.isNotEmpty) return username;

  if (comment.userId != null) return 'User #${comment.userId}';
  return 'User';
}

String commentUsername(CommentItem comment) {
  if (comment.isDeleted) return '';

  final username = comment.username?.trim();
  if (username == null || username.isEmpty) return '';
  return username;
}