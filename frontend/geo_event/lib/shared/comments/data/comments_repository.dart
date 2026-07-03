import '../models/comment_item.dart';
import 'comments_api.dart';

class CommentsRepository {
  const CommentsRepository(this._api);

  final CommentsApi _api;

  Future<List<CommentItem>> getEventComments(int eventId) =>
      _api.getEventComments(eventId);

  Future<List<CommentItem>> getReplies(int commentId) =>
      _api.getReplies(commentId);

  Future<CommentItem> createComment({
    required int eventId,
    required String content,
    int? parentCommentId,
  }) =>
      _api.createComment(
        eventId: eventId,
        content: content,
        parentCommentId: parentCommentId,
      );

  Future<CommentItem> updateComment({
    required int commentId,
    required String content,
  }) =>
      _api.updateComment(
        commentId: commentId,
        content: content,
      );

  Future<void> deleteComment(int commentId) => _api.deleteComment(commentId);

  Future<void> likeComment(int commentId) => _api.likeComment(commentId);

  Future<void> unlikeComment(int commentId) => _api.unlikeComment(commentId);
}