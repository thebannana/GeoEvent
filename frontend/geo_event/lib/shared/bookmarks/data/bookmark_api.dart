import 'package:dio/dio.dart';

import '../../events/models/paged_result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/bookmark.dart';

class BookmarkApi {
  const BookmarkApi(this.dio);

  final Dio dio;

  Future<PagedResult<Bookmark>> getBookmarksPaged({
    String? searchTerm,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await dio.get(
      ApiEndpoints.bookmarks,
      queryParameters: {
        if (searchTerm != null && searchTerm.trim().isNotEmpty)
          'searchTerm': searchTerm.trim(),
        'page': page,
        'pageSize': pageSize.clamp(1, 50),
      },
    );

    final raw = response.data;

    if (raw is Map) {
      return PagedResult<Bookmark>.fromJson(
        Map<String, dynamic>.from(raw),
        Bookmark.fromJson,
      );
    }

    final items = extractList(raw)
        .whereType<Map>()
        .map((e) => Bookmark.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return PagedResult<Bookmark>(
      items: items,
      totalCount: items.length,
      page: page,
      pageSize: pageSize,
      totalPages: 1,
      hasNextPage: false,
      hasPreviousPage: page > 1,
    );
  }

  Future<Bookmark> createBookmark({
    required int eventId,
    String? memo,
  }) async {
    final normalizedMemo = memo?.trim();

    final response = await dio.post(
      ApiEndpoints.bookmarks,
      data: {
        'eventId': eventId,
        if (normalizedMemo != null && normalizedMemo.isNotEmpty)
          'memo': normalizedMemo,
      },
    );

    return parseBookmark(response.data, 'Invalid bookmark create response.');
  }

  Future<Bookmark> updateBookmark({
    required int bookmarkId,
    String? memo,
  }) async {
    final trimmedMemo = memo?.trim();

    final response = await dio.patch(
      ApiEndpoints.bookmarkById(bookmarkId),
      data: {'memo': trimmedMemo},
    );

    return parseBookmark(response.data, 'Invalid bookmark update response.');
  }

  Future<void> deleteBookmark(int bookmarkId) async {
    await dio.delete(ApiEndpoints.bookmarkById(bookmarkId));
  }

  List<dynamic> extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      for (final key in ['items', 'Items', 'data', 'Data', 'results', 'Results']) {
        final value = map[key];
        if (value is List) return value;
      }
    }
    throw const FormatException('Invalid bookmarks response format.');
  }

  Bookmark parseBookmark(dynamic raw, String message) {
    if (raw is Map<String, dynamic>) return Bookmark.fromJson(raw);
    if (raw is Map) return Bookmark.fromJson(Map<String, dynamic>.from(raw));
    throw FormatException(message);
  }
}