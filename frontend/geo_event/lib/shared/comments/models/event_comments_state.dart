import '../../../../shared/comments/models/comment_item.dart';

class EventCommentsState {
  final List<CommentItem> comments;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isSubmitting;
  final String? error;
  final int? replyingToCommentId;
  final int? editingCommentId;
  final int page;
  final int pageSize;
  final int totalCount;
  final bool hasMore;

  const EventCommentsState({
    this.comments = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.isSubmitting = false,
    this.error,
    this.replyingToCommentId,
    this.editingCommentId,
    this.page = 0,
    this.pageSize = 20,
    this.totalCount = 0,
    this.hasMore = true,
  });

  bool get hasError => error != null && error!.trim().isNotEmpty;

  EventCommentsState copyWith({
    List<CommentItem>? comments,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
    int? replyingToCommentId,
    bool clearReplyingTo = false,
    int? editingCommentId,
    bool clearEditing = false,
    int? page,
    int? pageSize,
    int? totalCount,
    bool? hasMore,
  }) {
    return EventCommentsState(
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : error ?? this.error,
      replyingToCommentId: clearReplyingTo
          ? null
          : replyingToCommentId ?? this.replyingToCommentId,
      editingCommentId:
          clearEditing ? null : editingCommentId ?? this.editingCommentId,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}