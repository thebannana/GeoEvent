import 'package:dio/dio.dart';

import '../models/comment_item.dart';

class CommentsApi {
  final Dio dio;

  CommentsApi(this.dio);

  Future<List<CommentItem>> getEventComments(int eventId) async {
    final response = await dio.get('/api/comments/event/$eventId');
    final items = _extractList(response.data);
    return items.map(CommentItem.fromJson).toList();
  }

  Future<List<CommentItem>> getReplies(int commentId) async {
    final response = await dio.get('/api/comments/$commentId/replies');
    final items = _extractList(response.data);
    return items.map(CommentItem.fromJson).toList();
  }

  Future<CommentItem> createComment({
    required int eventId,
    required String content,
    int? parentCommentId,
  }) async {
    final response = await dio.post(
      '/api/comments',
      data: {
        'eventId': eventId,
        'content': content,
        if (parentCommentId != null) 'parentCommentId': parentCommentId,
      },
    );

    return CommentItem.fromJson(_asMap(response.data));
  }

  Future<CommentItem> updateComment({
    required int commentId,
    required String content,
  }) async {
    final response = await dio.put(
      '/api/comments/$commentId',
      data: {
        'content': content,
      },
    );

    return CommentItem.fromJson(_asMap(response.data));
  }

  Future<void> deleteComment(int commentId) async {
    await dio.delete('/api/comments/$commentId');
  }

  Future<void> likeComment(int commentId) async {
    await dio.post('/api/comments/$commentId/like');
  }

  Future<void> unlikeComment(int commentId) async {
    await dio.delete('/api/comments/$commentId/like');
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw Exception('Invalid response format.');
  }

  List<Map<String, dynamic>> _extractList(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      for (final key in ['items', 'data', 'results', 'comments', 'replies']) {
        final value = map[key];
        if (value is List) {
          return value
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
    }

    return const [];
  }
}