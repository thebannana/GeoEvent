import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../shared/comments/models/comment_item.dart';
import '../../../../shared/comments/providers/comment_providers.dart';
import '../../../shared/comments/data/comments_repository.dart';
import '../../../shared/comments/models/event_comments_state.dart';

final eventCommentsControllerProvider = StateNotifierProvider.autoDispose
    .family<EventCommentsController, EventCommentsState, int>((ref, eventId) {
  return EventCommentsController(ref, eventId);
});

class EventCommentsController extends StateNotifier<EventCommentsState> {
  EventCommentsController(this._ref, this._eventId)
      : super(const EventCommentsState()) {
    load();
  }

  final Ref _ref;
  final int _eventId;

  CommentsRepository get _repo => _ref.read(commentsRepositoryProvider);

  Future<void> load() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final comments = await _repo.getEventComments(_eventId);
      if (!mounted) return;

      state = state.copyWith(
        comments: comments,
        isLoading: false,
      );
    } catch (e, st) {
      if (!mounted) return;

      state = state.copyWith(
        isLoading: false,
        error: ErrorMapper.toMessage(e, stackTrace: st),
      );
    }
  }

  Future<void> refresh() async {
    try {
      final comments = await _repo.getEventComments(_eventId);
      if (!mounted) return;

      state = state.copyWith(
        comments: comments,
        clearError: true,
      );
    } catch (e, st) {
      if (!mounted) return;

      state = state.copyWith(
        error: ErrorMapper.toMessage(e, stackTrace: st),
      );
    }
  }

  void startReply(int commentId) {
    if (!mounted) return;

    state = state.copyWith(
      replyingToCommentId: commentId,
      clearEditing: true,
      clearError: true,
    );
  }

  void cancelReply() {
    if (!mounted) return;
    state = state.copyWith(clearReplyingTo: true);
  }

  void startEdit(int commentId) {
    if (!mounted) return;

    state = state.copyWith(
      editingCommentId: commentId,
      clearReplyingTo: true,
      clearError: true,
    );
  }

  void cancelEdit() {
    if (!mounted) return;
    state = state.copyWith(clearEditing: true);
  }

  Future<bool> submitComment(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || state.isSubmitting) return false;

    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
    );

    try {
      final replyingTo = state.replyingToCommentId;

      final created = await _repo.createComment(
        eventId: _eventId,
        content: text,
        parentCommentId: replyingTo,
      );

      if (!mounted) return false;

      if (replyingTo != null) {
        final updated = _appendReply(
          state.comments,
          replyingTo,
          created.copyWith(
            isReply: true,
            areRepliesLoaded: true,
          ),
        );

        state = state.copyWith(
          comments: updated,
          isSubmitting: false,
          clearReplyingTo: true,
          clearEditing: true,
        );
      } else {
        state = state.copyWith(
          comments: [created, ...state.comments],
          isSubmitting: false,
          clearReplyingTo: true,
          clearEditing: true,
        );
      }

      return true;
    } catch (e, st) {
      if (!mounted) return false;

      state = state.copyWith(
        isSubmitting: false,
        error: ErrorMapper.toMessage(e, stackTrace: st),
      );
      return false;
    }
  }

  Future<bool> saveEdit({
    required int commentId,
    required String rawText,
  }) async {
    final text = rawText.trim();
    if (text.isEmpty || state.isSubmitting) return false;

    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
    );

    try {
      final updated = await _repo.updateComment(
        commentId: commentId,
        content: text,
      );

      if (!mounted) return false;

      state = state.copyWith(
        comments: _replaceComment(state.comments, updated),
        isSubmitting: false,
        clearEditing: true,
      );

      return true;
    } catch (e, st) {
      if (!mounted) return false;

      state = state.copyWith(
        isSubmitting: false,
        error: ErrorMapper.toMessage(e, stackTrace: st),
      );
      return false;
    }
  }

  Future<void> deleteComment(int commentId) async {
    final before = state.comments;

    state = state.copyWith(
      comments: _markDeleted(before, commentId),
      clearError: true,
    );

    try {
      await _repo.deleteComment(commentId);
    } catch (e, st) {
      if (!mounted) return;

      state = state.copyWith(
        comments: before,
        error: ErrorMapper.toMessage(e, stackTrace: st),
      );
    }
  }

  Future<void> toggleLike(CommentItem comment) async {
    final optimistic = comment.copyWith(
      isLiked: !comment.isLiked,
      likesCount: comment.isLiked
          ? (comment.likesCount > 0 ? comment.likesCount - 1 : 0)
          : comment.likesCount + 1,
    );

    final before = state.comments;

    state = state.copyWith(
      comments: _replaceComment(before, optimistic),
      clearError: true,
    );

    try {
      if (comment.isLiked) {
        await _repo.unlikeComment(comment.commentId);
      } else {
        await _repo.likeComment(comment.commentId);
      }
    } catch (e, st) {
      if (!mounted) return;

      state = state.copyWith(
        comments: before,
        error: ErrorMapper.toMessage(e, stackTrace: st),
      );
    }
  }

  Future<void> loadReplies(int commentId) async {
    final target = _findComment(state.comments, commentId);
    if (target == null || target.isReplyLoading || target.areRepliesLoaded) {
      return;
    }

    state = state.copyWith(
      comments: _setReplyLoading(state.comments, commentId, true),
      clearError: true,
    );

    try {
      final replies = await _repo.getReplies(commentId);
      if (!mounted) return;

      state = state.copyWith(
        comments: _setReplies(state.comments, commentId, replies),
      );
    } catch (e, st) {
      if (!mounted) return;

      state = state.copyWith(
        comments: _setReplyLoading(state.comments, commentId, false),
        error: ErrorMapper.toMessage(e, stackTrace: st),
      );
    }
  }

  CommentItem? _findComment(List<CommentItem> items, int id) {
    for (final item in items) {
      if (item.commentId == id) return item;
      final nested = _findComment(item.replies, id);
      if (nested != null) return nested;
    }
    return null;
  }

  List<CommentItem> _replaceComment(
    List<CommentItem> items,
    CommentItem updated,
  ) {
    return items.map((item) {
      if (item.commentId == updated.commentId) return updated;
      if (item.replies.isEmpty) return item;
      return item.copyWith(
        replies: _replaceComment(item.replies, updated),
      );
    }).toList(growable: false);
  }

  List<CommentItem> _markDeleted(List<CommentItem> items, int commentId) {
    return items.map((item) {
      if (item.commentId == commentId) {
        return item.copyWith(
          content: 'Comment deleted.',
          isDeleted: true,
        );
      }
      if (item.replies.isEmpty) return item;
      return item.copyWith(
        replies: _markDeleted(item.replies, commentId),
      );
    }).toList(growable: false);
  }

  List<CommentItem> _appendReply(
    List<CommentItem> items,
    int parentId,
    CommentItem reply,
  ) {
    return items.map((item) {
      if (item.commentId == parentId) {
        return item.copyWith(
          replies: [...item.replies, reply],
          areRepliesLoaded: true,
          isReplyLoading: false,
          replyCount: item.replyCount + 1,
        );
      }
      if (item.replies.isEmpty) return item;
      return item.copyWith(
        replies: _appendReply(item.replies, parentId, reply),
      );
    }).toList(growable: false);
  }

  List<CommentItem> _setReplyLoading(
    List<CommentItem> items,
    int commentId,
    bool loading,
  ) {
    return items.map((item) {
      if (item.commentId == commentId) {
        return item.copyWith(isReplyLoading: loading);
      }
      if (item.replies.isEmpty) return item;
      return item.copyWith(
        replies: _setReplyLoading(item.replies, commentId, loading),
      );
    }).toList(growable: false);
  }

  List<CommentItem> _setReplies(
    List<CommentItem> items,
    int commentId,
    List<CommentItem> replies,
  ) {
    return items.map((item) {
      if (item.commentId == commentId) {
        return item.copyWith(
          replies: replies,
          replyCount: replies.length,
          areRepliesLoaded: true,
          isReplyLoading: false,
        );
      }
      if (item.replies.isEmpty) return item;
      return item.copyWith(
        replies: _setReplies(item.replies, commentId, replies),
      );
    }).toList(growable: false);
  }
}