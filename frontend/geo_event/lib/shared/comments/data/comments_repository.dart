import '../models/comment_item.dart';
import 'comments_api.dart';

class CommentsRepository {
  final CommentsApi api;

  CommentsRepository(this.api);

  Future<List<CommentItem>> getEventComments(int eventId) {
    return api.getEventComments(eventId);
  }

  Future<List<CommentItem>> getReplies(int commentId) {
    return api.getReplies(commentId);
  }

  Future<CommentItem> createComment({
    required int eventId,
    required String content,
    int? parentCommentId,
  }) {
    return api.createComment(
      eventId: eventId,
      content: content,
      parentCommentId: parentCommentId,
    );
  }

  Future<CommentItem> updateComment({
    required int commentId,
    required String content,
  }) {
    return api.updateComment(
      commentId: commentId,
      content: content,
    );
  }

  Future<void> deleteComment(int commentId) {
    return api.deleteComment(commentId);
  }

  Future<void> likeComment(int commentId) {
    return api.likeComment(commentId);
  }

  Future<void> unlikeComment(int commentId) {
    return api.unlikeComment(commentId);
  }
}