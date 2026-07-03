import '../../../../shared/comments/models/comment_item.dart';

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