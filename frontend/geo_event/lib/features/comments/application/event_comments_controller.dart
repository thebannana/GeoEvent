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
        comments: _mergeTopLevelWithPreservedReplies(
          oldItems: state.comments,
          newItems: page.items,
        ),
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
  if (state.isLoading || state.isSubmitting || state.isLoadingMore) return;

  final expandedReplyParents = state.comments
      .where((c) => c.areRepliesLoaded)
      .map((c) => c.commentId)
      .toList(growable: false);

  state = state.copyWith(
    isLoading: true,
    isLoadingMore: false,
    clearError: true,
  );

  try {
    final page = await _repo.getEventComments(
      _eventId,
      page: 1,
      pageSize: state.pageSize <= 0 ? _defaultPageSize : state.pageSize,
    );

    if (!mounted) return;

    state = state.copyWith(
      comments: page.items,
      isLoading: false,
      page: page.page,
      pageSize: page.pageSize,
      totalCount: page.totalCount,
      hasMore: page.hasNextPage,
      clearError: true,
    );

    for (final commentId in expandedReplyParents) {
      if (!mounted) return;

      final stillExists = state.comments.any((c) => c.commentId == commentId);
      if (!stillExists) continue;

      final repliesPage = await _repo.getReplies(
        commentId,
        page: 1,
        pageSize: _defaultPageSize,
      );

      if (!mounted) return;

      state = state.copyWith(
        comments: _setRepliesPage(
          state.comments,
          commentId,
          repliesPage,
        ),
      );
    }
  } catch (e, st) {
    if (!mounted) return;

    state = state.copyWith(
      isLoading: false,
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

      final mergedIncoming = _mergeTopLevelWithPreservedReplies(
        oldItems: state.comments,
        newItems: page.items,
      );

      state = state.copyWith(
        comments: [
          ...state.comments,
          ..._excludeExistingTopLevelComments(
            existing: state.comments,
            incoming: mergedIncoming,
          ),
        ],
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
      final updated = comment.isLiked
          ? await _repo.unlikeComment(comment.commentId)
          : await _repo.likeComment(comment.commentId);

      if (!mounted) return;

      state = state.copyWith(
        comments: _replaceComment(state.comments, updated),
      );
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
          replies: updated.replies.isNotEmpty ? updated.replies : item.replies,
          areRepliesLoaded: item.areRepliesLoaded || updated.areRepliesLoaded,
          isReplyLoading: item.isReplyLoading,
          isLoadingMoreReplies: item.isLoadingMoreReplies,
          hasMoreReplies:
              item.areRepliesLoaded ? item.hasMoreReplies : updated.hasMoreReplies,
          repliesPage: item.areRepliesLoaded ? item.repliesPage : updated.repliesPage,
          repliesPageSize:
              item.areRepliesLoaded ? item.repliesPageSize : updated.repliesPageSize,
          repliesTotalCount: item.areRepliesLoaded
              ? item.repliesTotalCount
              : updated.repliesTotalCount,
          replyCount: updated.replyCount > 0 ? updated.replyCount : item.replyCount,
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
        final existingReplies = item.replies
            .where((r) => r.commentId != reply.commentId)
            .toList(growable: false);

        final nextReplies = [...existingReplies, reply];
        final nextReplyCount = (item.replyCount < nextReplies.length)
            ? nextReplies.length
            : item.replyCount + 1;

        return item.copyWith(
          replies: nextReplies,
          areRepliesLoaded: true,
          isReplyLoading: false,
          isLoadingMoreReplies: false,
          replyCount: nextReplyCount,
          repliesPage: item.repliesPage == 0 ? 1 : item.repliesPage,
          repliesPageSize:
              item.repliesPageSize <= 0 ? _defaultPageSize : item.repliesPageSize,
          repliesTotalCount: item.repliesTotalCount < nextReplies.length
              ? nextReplies.length
              : item.repliesTotalCount + 1,
          hasMoreReplies: false,
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
          replyCount: page.totalCount > item.replyCount
              ? page.totalCount
              : item.replyCount,
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
        final mergedMap = <int, CommentItem>{
          for (final reply in item.replies) reply.commentId: reply,
          for (final reply in page.items) reply.commentId: reply,
        };
        final mergedReplies = mergedMap.values.toList(growable: false);

        return item.copyWith(
          replies: mergedReplies,
          replyCount: page.totalCount > mergedReplies.length
              ? page.totalCount
              : mergedReplies.length,
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

  List<CommentItem> _mergeTopLevelWithPreservedReplies({
    required List<CommentItem> oldItems,
    required List<CommentItem> newItems,
  }) {
    final oldById = {
      for (final item in oldItems) item.commentId: item,
    };

    return newItems.map((newItem) {
      final oldItem = oldById[newItem.commentId];
      if (oldItem == null) return newItem;

      final shouldPreserveReplies =
          oldItem.areRepliesLoaded || oldItem.replies.isNotEmpty;

      return newItem.copyWith(
        replies: shouldPreserveReplies ? oldItem.replies : newItem.replies,
        areRepliesLoaded:
            shouldPreserveReplies ? true : newItem.areRepliesLoaded,
        isReplyLoading: false,
        isLoadingMoreReplies: false,
        hasMoreReplies:
            shouldPreserveReplies ? oldItem.hasMoreReplies : newItem.hasMoreReplies,
        repliesPage:
            shouldPreserveReplies ? oldItem.repliesPage : newItem.repliesPage,
        repliesPageSize:
            shouldPreserveReplies ? oldItem.repliesPageSize : newItem.repliesPageSize,
        repliesTotalCount: shouldPreserveReplies
            ? (oldItem.repliesTotalCount > 0
                ? oldItem.repliesTotalCount
                : oldItem.replies.length)
            : newItem.repliesTotalCount,
        replyCount: oldItem.replyCount > newItem.replyCount
            ? oldItem.replyCount
            : newItem.replyCount,
      );
    }).toList(growable: false);
  }

  List<CommentItem> _excludeExistingTopLevelComments({
    required List<CommentItem> existing,
    required List<CommentItem> incoming,
  }) {
    final existingIds = existing.map((e) => e.commentId).toSet();
    return incoming
        .where((item) => !existingIds.contains(item.commentId))
        .toList(growable: false);
  }
}