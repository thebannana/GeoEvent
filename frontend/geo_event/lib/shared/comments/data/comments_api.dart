import 'package:dio/dio.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/comment_item.dart';
import '../models/paged_response.dart';

class CommentsApi {
  const CommentsApi(this._dio);

  final Dio _dio;
  static const int maxPageSize = 50;
  static const int defaultPageSize = 20;

  Future<PagedResponse<CommentItem>> getEventComments(
    int eventId, {
    int page = 1,
    int pageSize = defaultPageSize,
  }) async {
    try {
      final safePage = page <= 0 ? 1 : page;
      final safePageSize = pageSize <= 0
          ? defaultPageSize
          : (pageSize > maxPageSize ? maxPageSize : pageSize);

      final response = await _dio.get(
        ApiEndpoints.commentsForEvent(eventId),
        queryParameters: {
          'page': safePage,
          'pageSize': safePageSize,
        },
      );

      return PagedResponse<CommentItem>.fromJson(
        _asMap(response.data),
        CommentItem.fromJson,
      );
    } catch (e, st) {
      throw ErrorMapper.toAppException(e, stackTrace: st);
    }
  }

  Future<PagedResponse<CommentItem>> getReplies(
    int commentId, {
    int page = 1,
    int pageSize = defaultPageSize,
  }) async {
    try {
      final safePage = page <= 0 ? 1 : page;
      final safePageSize = pageSize <= 0
          ? defaultPageSize
          : (pageSize > maxPageSize ? maxPageSize : pageSize);

      final response = await _dio.get(
        ApiEndpoints.commentReplies(commentId),
        queryParameters: {
          'page': safePage,
          'pageSize': safePageSize,
        },
      );

      return PagedResponse<CommentItem>.fromJson(
        _asMap(response.data),
        CommentItem.fromJson,
      );
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
          'content': content.trim(),
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
        data: {'content': content.trim()},
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

  Future<CommentItem> likeComment(int commentId) async {
    try {
      final response = await _dio.post(ApiEndpoints.likeComment(commentId));
      return CommentItem.fromJson(_asMap(response.data));
    } catch (e, st) {
      throw ErrorMapper.toAppException(e, stackTrace: st);
    }
  }

  Future<CommentItem> unlikeComment(int commentId) async {
    try {
      final response = await _dio.delete(ApiEndpoints.likeComment(commentId));
      return CommentItem.fromJson(_asMap(response.data));
    } catch (e, st) {
      throw ErrorMapper.toAppException(e, stackTrace: st);
    }
  }

  static Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw const FormatException('Invalid response format.');
  }
}