import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../shared/comments/models/comment_item.dart';
import '../../../../shared/comments/providers/comment_providers.dart';
import '../../../shared/comments/data/comments_repository.dart';
import '../../../shared/comments/models/event_comments_state.dart';
import '../../../shared/comments/models/paged_response.dart';

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

  static const int _defaultPageSize = 20;

  CommentsRepository get _repo => _ref.read(commentsRepositoryProvider);

  Future<void> load() async {
    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      clearError: true,
    );

    try {
      final page = await _repo.getEventComments(
        _eventId,
        page: 1,
        pageSize: _defaultPageSize,
      );

      if (!mounted) return;

      state = state.copyWith(
        comments: page.items,
        isLoading: false,
        page: page.page,
        pageSize: page.pageSize,
        totalCount: page.totalCount,
        hasMore: page.hasNextPage,
      );
    } catch (e, st) {
      if (!mounted) return;

      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: ErrorMapper.toMessage(e, stackTrace: st),
      );
    }
  }

  Future<void> refresh() async {
    try {
      final page = await _repo.getEventComments(
        _eventId,
        page: 1,
        pageSize: state.pageSize <= 0 ? _defaultPageSize : state.pageSize,
      );

      if (!mounted) return;

      state = state.copyWith(
        comments: page.items,
        page: page.page,
        pageSize: page.pageSize,
        totalCount: page.totalCount,
        hasMore: page.hasNextPage,
        clearError: true,
      );
    } catch (e, st) {
      if (!mounted) return;

      state = state.copyWith(
        error: ErrorMapper.toMessage(e, stackTrace: st),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(
      isLoadingMore: true,
      clearError: true,
    );

    try {
      final nextPage = state.page + 1;
      final page = await _repo.getEventComments(
        _eventId,
        page: nextPage,
        pageSize: state.pageSize <= 0 ? _defaultPageSize : state.pageSize,
      );

      if (!mounted) return;

      state = state.copyWith(
        comments: [...state.comments, ...page.items],
        isLoadingMore: false,
        page: page.page,
        pageSize: page.pageSize,
        totalCount: page.totalCount,
        hasMore: page.hasNextPage,
      );
    } catch (e, st) {
      if (!mounted) return;

      state = state.copyWith(
        isLoadingMore: false,
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
          totalCount: state.totalCount + 1,
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
    if (target == null || target.isReplyLoading) return;

    state = state.copyWith(
      comments: _setReplyLoading(state.comments, commentId, true),
      clearError: true,
    );

    try {
      final page = await _repo.getReplies(
        commentId,
        page: 1,
        pageSize: _defaultPageSize,
      );

      if (!mounted) return;

      state = state.copyWith(
        comments: _setRepliesPage(
          state.comments,
          commentId,
          page,
        ),
      );
    } catch (e, st) {
      if (!mounted) return;

      state = state.copyWith(
        comments: _setReplyLoading(state.comments, commentId, false),
        error: ErrorMapper.toMessage(e, stackTrace: st),
      );
    }
  }

  Future<void> loadMoreReplies(int commentId) async {
    final target = _findComment(state.comments, commentId);
    if (target == null ||
        target.isReplyLoading ||
        target.isLoadingMoreReplies ||
        !target.hasMoreReplies) {
      return;
    }

    state = state.copyWith(
      comments: _setReplyLoadingMore(state.comments, commentId, true),
      clearError: true,
    );

    try {
      final nextPage = target.repliesPage + 1;
      final page = await _repo.getReplies(
        commentId,
        page: nextPage,
        pageSize: target.repliesPageSize <= 0
            ? _defaultPageSize
            : target.repliesPageSize,
      );

      if (!mounted) return;

      state = state.copyWith(
        comments: _appendRepliesPage(
          state.comments,
          commentId,
          page,
        ),
      );
    } catch (e, st) {
      if (!mounted) return;

      state = state.copyWith(
        comments: _setReplyLoadingMore(state.comments, commentId, false),
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
      if (item.commentId == updated.commentId) {
        return updated.copyWith(
          replies: item.replies,
          areRepliesLoaded: item.areRepliesLoaded,
          isReplyLoading: item.isReplyLoading,
          isLoadingMoreReplies: item.isLoadingMoreReplies,
          hasMoreReplies: item.hasMoreReplies,
          repliesPage: item.repliesPage,
          repliesPageSize: item.repliesPageSize,
          repliesTotalCount: item.repliesTotalCount,
        );
      }
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
        final nextReplies = [...item.replies, reply];
        final nextReplyCount = item.replyCount + 1;
        return item.copyWith(
          replies: nextReplies,
          areRepliesLoaded: true,
          isReplyLoading: false,
          isLoadingMoreReplies: false,
          replyCount: nextReplyCount,
          repliesPage: item.repliesPage == 0 ? 1 : item.repliesPage,
          repliesPageSize: item.repliesPageSize,
          repliesTotalCount: item.repliesTotalCount > 0
              ? item.repliesTotalCount + 1
              : nextReplyCount,
          hasMoreReplies: item.repliesTotalCount > 0
              ? nextReplies.length < item.repliesTotalCount + 1
              : false,
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

  List<CommentItem> _setReplyLoadingMore(
    List<CommentItem> items,
    int commentId,
    bool loading,
  ) {
    return items.map((item) {
      if (item.commentId == commentId) {
        return item.copyWith(isLoadingMoreReplies: loading);
      }
      if (item.replies.isEmpty) return item;
      return item.copyWith(
        replies: _setReplyLoadingMore(item.replies, commentId, loading),
      );
    }).toList(growable: false);
  }

  List<CommentItem> _setRepliesPage(
    List<CommentItem> items,
    int commentId,
    PagedResponse<CommentItem> page,
  ) {
    return items.map((item) {
      if (item.commentId == commentId) {
        return item.copyWith(
          replies: page.items,
          replyCount: item.replyCount > 0 ? item.replyCount : page.totalCount,
          repliesTotalCount: page.totalCount,
          areRepliesLoaded: true,
          isReplyLoading: false,
          isLoadingMoreReplies: false,
          repliesPage: page.page,
          repliesPageSize: page.pageSize,
          hasMoreReplies: page.hasNextPage,
        );
      }
      if (item.replies.isEmpty) return item;
      return item.copyWith(
        replies: _setRepliesPage(item.replies, commentId, page),
      );
    }).toList(growable: false);
  }

  List<CommentItem> _appendRepliesPage(
    List<CommentItem> items,
    int commentId,
    PagedResponse<CommentItem> page,
  ) {
    return items.map((item) {
      if (item.commentId == commentId) {
        return item.copyWith(
          replies: [...item.replies, ...page.items],
          repliesTotalCount: page.totalCount,
          areRepliesLoaded: true,
          isReplyLoading: false,
          isLoadingMoreReplies: false,
          repliesPage: page.page,
          repliesPageSize: page.pageSize,
          hasMoreReplies: page.hasNextPage,
        );
      }
      if (item.replies.isEmpty) return item;
      return item.copyWith(
        replies: _appendRepliesPage(item.replies, commentId, page),
      );
    }).toList(growable: false);
  }
}