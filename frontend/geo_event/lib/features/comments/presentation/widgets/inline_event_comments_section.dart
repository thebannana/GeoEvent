import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_time_extensions.dart';
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF121216),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comments',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 14),
          if (errorText != null && errorText.trim().isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                errorText,
                style: const TextStyle(color: Colors.white),
              ),
            ),
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
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (state.comments.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'No comments yet. Start the conversation.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
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
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh comments'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white60,
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

class _ComposerStateBanner extends StatelessWidget {
  final bool isEditing;
  final VoidCallback onCancel;

  const _ComposerStateBanner({
    required this.isEditing,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            isEditing ? Icons.edit_outlined : Icons.reply_rounded,
            color: Colors.white70,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isEditing ? 'Editing comment' : 'Replying to comment',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
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
              color: Colors.white.withValues(alpha: 0.025),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 5,
              style: const TextStyle(color: Colors.white, height: 1.3),
              decoration: InputDecoration(
                hintText: isEditing
                    ? 'Edit your comment...'
                    : isReplying
                        ? 'Write a reply...'
                        : 'Add a comment...',
                hintStyle: const TextStyle(
                  color: Colors.white38,
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
        GestureDetector(
          onTap: isSubmitting ? null : onSubmit,
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF3797EF).withValues(
                alpha: isSubmitting ? 0.5 : 1,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    isEditing ? 'Save' : 'Post',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
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
                    color: comment.isLiked
                        ? const Color(0xFFFF6B81)
                        : Colors.white60,
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
                      onTap: comment.isDeleted
                          ? null
                          : () => onReportTap!(comment),
                    ),
                  if (canManage)
                    _ActionTextButton(
                      label: 'Edit',
                      onTap: onEditTap,
                    ),
                  if (canManage)
                    _ActionTextButton(
                      label: 'Delete',
                      color: Colors.redAccent,
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
                GestureDetector(
                  onTap: onLoadRepliesTap,
                  child: Text(
                    comment.isReplyLoading
                        ? 'Loading replies...'
                        : 'View ${comment.replyCount} repl${comment.replyCount == 1 ? 'y' : 'ies'}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
                        color: Colors.white.withValues(alpha: 0.08),
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
                              onEditTap: _canManage(currentUserId, reply.userId) &&
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
        GestureDetector(
          onTap: comment.isDeleted ? null : onLikeTap,
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              comment.isLiked ? Icons.favorite : Icons.favorite_border,
              size: 18,
              color: comment.isLiked
                  ? const Color(0xFFFF6B81)
                  : Colors.white54,
            ),
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
    final canManage =
        currentUserId != null && reply.userId != null && currentUserId == reply.userId;

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
                    color: reply.isLiked
                        ? const Color(0xFFFF6B81)
                        : Colors.white60,
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
                      color: Colors.redAccent,
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
        GestureDetector(
          onTap: reply.isDeleted ? null : onLikeTap,
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              reply.isLiked ? Icons.favorite : Icons.favorite_border,
              size: 16,
              color: reply.isLiked
                  ? const Color(0xFFFF6B81)
                  : Colors.white54,
            ),
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
    final authorName = commentAuthorName(comment);
    final username = commentUsername(comment);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isReply ? 12 : 13,
        vertical: isReply ? 9 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isReply ? 0.045 : 0.06),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                if (username.isNotEmpty)
                  Text(
                    '@$username',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
              ],
            )
          else
            const Text(
              'Deleted user',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          const SizedBox(height: 3),
          Text(
            comment.content,
            style: TextStyle(
              color: comment.isDeleted ? Colors.white38 : Colors.white70,
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

    if (avatarUrl != null && avatarUrl!.trim().isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: const Color(0xFF2B2B31),
        backgroundImage: NetworkImage(avatarUrl!),
        onBackgroundImageError: (_, __) {},
      );
    }

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Color(0xFF8E8E93),
            Color(0xFF5A5A60),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _buildInitials(String text) {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return '?';

    final parts = cleaned.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();

    return '${parts.first.characters.first}${parts[1].characters.first}'
        .toUpperCase();
  }
}

class _ActionTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;

  const _ActionTextButton({
    required this.label,
    required this.onTap,
    this.color = Colors.white60,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = onTap == null ? Colors.white24 : color;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Text(
        label,
        style: TextStyle(
          color: effectiveColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
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
      style: const TextStyle(
        color: Colors.white38,
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