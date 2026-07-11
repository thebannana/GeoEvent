import '../models/comment_item.dart';
import '../models/paged_response.dart';
import 'comments_api.dart';

class CommentsRepository {
  const CommentsRepository(this._api);

  final CommentsApi _api;

  Future<PagedResponse<CommentItem>> getEventComments(
    int eventId, {
    int page = 1,
    int pageSize = CommentsApi.defaultPageSize,
  }) {
    return _api.getEventComments(
      eventId,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<PagedResponse<CommentItem>> getReplies(
    int commentId, {
    int page = 1,
    int pageSize = CommentsApi.defaultPageSize,
  }) {
    return _api.getReplies(
      commentId,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<CommentItem> createComment({
    required int eventId,
    required String content,
    int? parentCommentId,
  }) {
    return _api.createComment(
      eventId: eventId,
      content: content,
      parentCommentId: parentCommentId,
    );
  }

  Future<CommentItem> updateComment({
    required int commentId,
    required String content,
  }) {
    return _api.updateComment(
      commentId: commentId,
      content: content,
    );
  }

  Future<void> deleteComment(int commentId) => _api.deleteComment(commentId);

  Future<CommentItem> likeComment(int commentId) => _api.likeComment(commentId);

  Future<CommentItem> unlikeComment(int commentId) =>
      _api.unlikeComment(commentId);
}