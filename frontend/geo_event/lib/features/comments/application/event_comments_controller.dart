import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/comments/models/comment_item.dart';
import '../../../../shared/comments/providers/comment_providers.dart';

class EventCommentsState {
  final List<CommentItem> comments;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final int? replyingToCommentId;
  final int? editingCommentId;

  const EventCommentsState({
    this.comments = const [],
    this.isLoading = true,
    this.isSubmitting = false,
    this.error,
    this.replyingToCommentId,
    this.editingCommentId,
  });

  bool get hasError => error != null && error!.trim().isNotEmpty;

  EventCommentsState copyWith({
    List<CommentItem>? comments,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
    int? replyingToCommentId,
    bool clearReplyingTo = false,
    int? editingCommentId,
    bool clearEditing = false,
  }) {
    return EventCommentsState(
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      replyingToCommentId: clearReplyingTo
          ? null
          : (replyingToCommentId ?? this.replyingToCommentId),
      editingCommentId:
          clearEditing ? null : (editingCommentId ?? this.editingCommentId),
    );
  }
}

final eventCommentsControllerProvider = StateNotifierProvider.autoDispose
    .family<EventCommentsController, EventCommentsState, int>((ref, eventId) {
  return EventCommentsController(ref, eventId);
});

class EventCommentsController extends StateNotifier<EventCommentsState> {
  final Ref ref;
  final int eventId;

  EventCommentsController(this.ref, this.eventId)
      : super(const EventCommentsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final comments =
          await ref.read(commentsRepositoryProvider).getEventComments(eventId);

      state = state.copyWith(
        comments: comments,
        isLoading: false,
        isSubmitting: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    try {
      final comments =
          await ref.read(commentsRepositoryProvider).getEventComments(eventId);

      state = state.copyWith(
        comments: comments,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void startReply(int commentId) {
    state = state.copyWith(
      replyingToCommentId: commentId,
      clearReplyingTo: false,
      clearEditing: true,
      clearError: true,
    );
  }

  void cancelReply() {
    state = state.copyWith(clearReplyingTo: true);
  }

  void startEdit(int commentId) {
    state = state.copyWith(
      editingCommentId: commentId,
      clearEditing: false,
      clearReplyingTo: true,
      clearError: true,
    );
  }

  void cancelEdit() {
    state = state.copyWith(clearEditing: true);
  }

  Future<void> submitComment(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty) return;

    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
    );

    try {
      final created = await ref.read(commentsRepositoryProvider).createComment(
            eventId: eventId,
            content: text,
            parentCommentId: state.replyingToCommentId,
          );

      if (state.replyingToCommentId != null) {
        final parentId = state.replyingToCommentId!;
        final updated = _appendReply(
          state.comments,
          parentId,
          created.copyWith(isReply: true),
        );

        state = state.copyWith(
          comments: updated,
          isSubmitting: false,
          clearReplyingTo: true,
        );
      } else {
        state = state.copyWith(
          comments: [created, ...state.comments],
          isSubmitting: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: e.toString(),
      );
    }
  }

  Future<void> saveEdit({
    required int commentId,
    required String rawText,
  }) async {
    final text = rawText.trim();
    if (text.isEmpty) return;

    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
    );

    try {
      final updated = await ref.read(commentsRepositoryProvider).updateComment(
            commentId: commentId,
            content: text,
          );

      state = state.copyWith(
        comments: _replaceComment(state.comments, updated),
        isSubmitting: false,
        clearEditing: true,
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: e.toString(),
      );
    }
  }

  Future<void> deleteComment(int commentId) async {
    final before = state.comments;
    state = state.copyWith(
      comments: _markDeleted(before, commentId),
      clearError: true,
    );

    try {
      await ref.read(commentsRepositoryProvider).deleteComment(commentId);
    } catch (e) {
      state = state.copyWith(
        comments: before,
        error: e.toString(),
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
        await ref.read(commentsRepositoryProvider).unlikeComment(comment.commentId);
      } else {
        await ref.read(commentsRepositoryProvider).likeComment(comment.commentId);
      }
    } catch (e) {
      state = state.copyWith(
        comments: before,
        error: e.toString(),
      );
    }
  }

  Future<void> loadReplies(int commentId) async {
    final target = _findComment(state.comments, commentId);
    if (target == null || target.isReplyLoading) return;

    state = state.copyWith(
      comments: _setReplyLoading(state.comments, commentId, true),
      clearError: true,
    );

    try {
      final replies =
          await ref.read(commentsRepositoryProvider).getReplies(commentId);

      state = state.copyWith(
        comments: _setReplies(state.comments, commentId, replies),
      );
    } catch (e) {
      state = state.copyWith(
        comments: _setReplyLoading(state.comments, commentId, false),
        error: e.toString(),
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

  List<CommentItem> _replaceComment(List<CommentItem> items, CommentItem updated) {
    return items.map((item) {
      if (item.commentId == updated.commentId) return updated;
      if (item.replies.isEmpty) return item;
      return item.copyWith(replies: _replaceComment(item.replies, updated));
    }).toList();
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
      return item.copyWith(replies: _markDeleted(item.replies, commentId));
    }).toList();
  }

  List<CommentItem> _appendReply(
    List<CommentItem> items,
    int parentId,
    CommentItem reply,
  ) {
    return items.map((item) {
      if (item.commentId == parentId) {
        final nextReplies = [...item.replies, reply];
        return item.copyWith(
          replies: nextReplies,
          areRepliesLoaded: true,
          isReplyLoading: false,
          replyCount: item.replyCount + 1,
        );
      }

      if (item.replies.isEmpty) return item;
      return item.copyWith(
        replies: _appendReply(item.replies, parentId, reply),
      );
    }).toList();
  }

  List<CommentItem> _setReplyLoading(
    List<CommentItem> items,
    int commentId,
    bool isLoading,
  ) {
    return items.map((item) {
      if (item.commentId == commentId) {
        return item.copyWith(isReplyLoading: isLoading);
      }
      if (item.replies.isEmpty) return item;
      return item.copyWith(
        replies: _setReplyLoading(item.replies, commentId, isLoading),
      );
    }).toList();
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
          areRepliesLoaded: true,
          isReplyLoading: false,
        );
      }
      if (item.replies.isEmpty) return item;
      return item.copyWith(
        replies: _setReplies(item.replies, commentId, replies),
      );
    }).toList();
  }
}