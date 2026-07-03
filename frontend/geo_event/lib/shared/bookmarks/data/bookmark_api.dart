import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../models/bookmark.dart';

class BookmarkApi {
  const BookmarkApi(this._dio);

  final Dio _dio;

  Future<List<Bookmark>> getBookmarks() async {
    final raw = (await _dio.get(ApiEndpoints.bookmarks)).data;
    final items = _extractList(raw);

    return items
        .whereType<Map>()
        .map((e) => Bookmark.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Bookmark> createBookmark({
    required int eventId,
    String? memo,
  }) async {
    final normalizedMemo = memo?.trim();

    final response = await _dio.post(
      ApiEndpoints.bookmarks,
      data: {
        'eventId': eventId,
        if (normalizedMemo != null && normalizedMemo.isNotEmpty)
          'memo': normalizedMemo,
      },
    );

    return _parseBookmark(response.data, 'Invalid bookmark create response.');
  }

  Future<Bookmark> updateBookmark({
    required int bookmarkId,
    String? memo,
  }) async {
    final trimmedMemo = memo?.trim();

    final response = await _dio.patch(
      ApiEndpoints.bookmarkById(bookmarkId),
      data: {
        'memo': trimmedMemo,
      },
    );

    return _parseBookmark(response.data, 'Invalid bookmark update response.');
  }

  Future<void> deleteBookmark(int bookmarkId) async {
    await _dio.delete(ApiEndpoints.bookmarkById(bookmarkId));
  }

List<dynamic> _extractList(dynamic raw) {
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

  Bookmark _parseBookmark(dynamic raw, String message) {
    if (raw is Map<String, dynamic>) {
      return Bookmark.fromJson(raw);
    }

    if (raw is Map) {
      return Bookmark.fromJson(Map<String, dynamic>.from(raw));
    }

    throw FormatException(message);
  }
}