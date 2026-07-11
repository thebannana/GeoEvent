import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/feedback/app_confirm_dialog.dart';
import '../../../../core/widgets/surfaces/app_surface_card.dart';
import '../../../../shared/comments/models/comment_item.dart';
import '../../../../shared/comments/models/event_comments_state.dart';
import '../../../../shared/reports/models/report_target_type.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../reports/presentation/screens/report_screen.dart';
import '../../application/event_comments_controller.dart';
import '../widgets/comment_composer.dart';
import '../widgets/comment_thread_list.dart';
import 'comment_meta.dart';

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
  final GlobalKey<FormState> _composerFormKey = GlobalKey<FormState>();
  bool _composerTouched = false;
  late final ProviderSubscription<EventCommentsState> _commentsSubscription;

  @override
  void initState() {
    super.initState();

    _commentsSubscription = ref.listenManual<EventCommentsState>(
      eventCommentsControllerProvider(widget.eventId),
      (previous, next) {
        final leftReplyMode =
            previous?.replyingToCommentId != null && next.replyingToCommentId == null;
        final leftEditMode =
            previous?.editingCommentId != null && next.editingCommentId == null;

        if (!mounted) return;

        if ((leftReplyMode || leftEditMode) && !next.isSubmitting) {
          _composerController.clear();
          _composerFormKey.currentState?.reset();
          FocusManager.instance.primaryFocus?.unfocus();
          setState(() => _composerTouched = false);
        }
      },
    );
  }

  @override
  void dispose() {
    _commentsSubscription.close();
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
          targetSubtitle: comment.content.trim(),
          targetImageUrl: comment.avatarUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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

    final isEditing = state.editingCommentId != null;
    final isReplying = state.replyingToCommentId != null;

    final submitDisabledReason = state.isSubmitting
        ? 'Your comment is being submitted.'
        : _composerController.text.trim().isEmpty
            ? (isEditing
                ? 'Enter updated comment text to save changes.'
                : isReplying
                    ? 'Enter a reply to enable posting.'
                    : 'Enter a comment to enable posting.')
            : null;

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
          if (state.error != null && state.error!.trim().isNotEmpty) ...[
            InlineErrorBanner(message: state.error!.trim()),
            const SizedBox(height: 12),
          ],
          CommentComposer(
            formKey: _composerFormKey,
            controller: _composerController,
            isEditing: isEditing,
            isReplying: isReplying,
            isSubmitting: state.isSubmitting,
            currentUserAvatarUrl: currentUserAvatarUrl,
            currentUserDisplayName: effectiveDisplayName,
            autovalidateMode: _composerTouched
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            submitDisabledReason: submitDisabledReason,
            onCancelMode: (isReplying || isEditing)
                ? () {
                    controller.cancelReply();
                    controller.cancelEdit();
                    _composerController.clear();
                    _composerFormKey.currentState?.reset();
                    FocusManager.instance.primaryFocus?.unfocus();
                    setState(() => _composerTouched = false);
                  }
                : null,
            validator: (value) {
              final requiredError = Validators.required(
                value,
                fieldName: isReplying ? 'Reply' : 'Comment',
              );
              if (requiredError != null) return requiredError;

              final trimmed = value!.trim();
              if (trimmed.length < 2) {
                return isReplying
                    ? 'Reply must be at least 2 characters.'
                    : 'Comment must be at least 2 characters.';
              }
              if (trimmed.length > 1000) {
                return isReplying
                    ? 'Reply must be at most 1000 characters.'
                    : 'Comment must be at most 1000 characters.';
              }
              return null;
            },
            onChanged: (_) {
              if (!_composerTouched) {
                setState(() => _composerTouched = true);
              } else {
                setState(() {});
              }
            },
            onSubmit: () async {
              FocusScope.of(context).unfocus();
              setState(() => _composerTouched = true);

              final isValid = _composerFormKey.currentState?.validate() ?? false;
              if (!isValid) return;

              final text = _composerController.text.trim();
              final editingId = state.editingCommentId;

              final ok = editingId != null
                  ? await controller.saveEdit(
                      commentId: editingId,
                      rawText: text,
                    )
                  : await controller.submitComment(text);

              if (!mounted) return;

              if (ok) {
                _composerController.clear();
                _composerController.value = const TextEditingValue(
                  text: '',
                  selection: TextSelection.collapsed(offset: 0),
                );
                _composerFormKey.currentState?.reset();
                controller.cancelReply();
                controller.cancelEdit();
                FocusScope.of(context).unfocus();
                setState(() => _composerTouched = false);
              }
            },
          ),
          const SizedBox(height: 18),
          CommentThreadList(
            state: state,
            currentUserId: widget.currentUserId,
            onRefresh: controller.refresh,
            onLoadMore: controller.loadMore,
            onLikeTap: controller.toggleLike,
            onLoadRepliesTap: controller.loadReplies,
            onLoadMoreRepliesTap: controller.loadMoreReplies,
            onReplyTap: (comment) {
              controller.cancelEdit();
              controller.startReply(comment.commentId);
              _composerController.clear();
              _composerFormKey.currentState?.reset();
              setState(() => _composerTouched = false);
            },
            onEditTap: (comment) {
              controller.cancelReply();
              controller.startEdit(comment.commentId);
              _composerController.text = comment.content.trim();
              _composerController.selection = TextSelection.collapsed(
                offset: _composerController.text.length,
              );
              setState(() => _composerTouched = false);
            },
            onDeleteTap: (comment) =>
                _deleteCommentWithConfirmation(comment.commentId),
            onReportTap: _openReportCommentScreen,
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCommentWithConfirmation(int commentId) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Delete comment?',
      message: 'This comment will be permanently removed.',
      confirmLabel: 'Delete',
    );

    if (confirmed != true) return;

    await ref
        .read(eventCommentsControllerProvider(widget.eventId).notifier)
        .deleteComment(commentId);
  }
}