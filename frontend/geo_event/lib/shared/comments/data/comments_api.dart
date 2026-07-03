import 'package:dio/dio.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/comment_item.dart';

class CommentsApi {
  const CommentsApi(this._dio);

  final Dio _dio;

  Future<List<CommentItem>> getEventComments(int eventId) async {
    try {
      final response = await _dio.get(ApiEndpoints.commentsForEvent(eventId));
      return _parseList(response.data);
    } catch (e, st) {
      throw ErrorMapper.toAppException(e, stackTrace: st);
    }
  }

  Future<List<CommentItem>> getReplies(int commentId) async {
    try {
      final response = await _dio.get(ApiEndpoints.commentReplies(commentId));
      return _parseList(response.data);
    } catch (e, st) {
      throw ErrorMapper.toAppException(e, stackTrace: st);
    }
  }

  Future<CommentItem> createComment({
    required int eventId,
    required String content,
    int? parentCommentId,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.commentsBase,
        data: {
          'eventId': eventId,
          'content': content,
          'parentCommentId': ?parentCommentId,
        },
      );
      return CommentItem.fromJson(_asMap(response.data));
    } catch (e, st) {
      throw ErrorMapper.toAppException(e, stackTrace: st);
    }
  }

  Future<CommentItem> updateComment({
    required int commentId,
    required String content,
  }) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.commentById(commentId),
        data: {'content': content},
      );
      return CommentItem.fromJson(_asMap(response.data));
    } catch (e, st) {
      throw ErrorMapper.toAppException(e, stackTrace: st);
    }
  }

  Future<void> deleteComment(int commentId) async {
    try {
      await _dio.delete(ApiEndpoints.commentById(commentId));
    } catch (e, st) {
      throw ErrorMapper.toAppException(e, stackTrace: st);
    }
  }

  Future<void> likeComment(int commentId) async {
    try {
      await _dio.post(ApiEndpoints.likeComment(commentId));
    } catch (e, st) {
      throw ErrorMapper.toAppException(e, stackTrace: st);
    }
  }

  Future<void> unlikeComment(int commentId) async {
    try {
      await _dio.delete(ApiEndpoints.likeComment(commentId));
    } catch (e, st) {
      throw ErrorMapper.toAppException(e, stackTrace: st);
    }
  }

  static Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw const FormatException('Invalid response format.');
  }

  static List<CommentItem> _parseList(dynamic raw) {
    final maps = _extractMaps(raw);
    return maps.map(CommentItem.fromJson).toList(growable: false);
  }

  static List<Map<String, dynamic>> _extractMaps(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);
    }

    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      for (final key in ['items', 'data', 'results', 'comments', 'replies']) {
        final value = map[key];
        if (value is List) {
          return value
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList(growable: false);
        }
      }
    }

    return const [];
  }
}