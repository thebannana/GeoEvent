import 'package:dio/dio.dart';

import '../models/bookmark.dart';

class BookmarkApi {
  final Dio _dio;

  const BookmarkApi(this._dio);

  Future<List<Bookmark>> getBookmarks() async {
    final response = await _dio.get('/api/bookmarks');
    final data = response.data;

    if (data is! List) {
      throw const FormatException('Invalid bookmarks response format');
    }

    return data
        .map(
          (e) => Bookmark.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<Bookmark> createBookmark({
    required int eventId,
    String? memo,
  }) async {
    final response = await _dio.post(
      '/api/bookmarks',
      data: {
        'eventId': eventId,
        if (memo != null && memo.trim().isNotEmpty) 'memo': memo.trim(),
      },
    );

    return Bookmark.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<Bookmark> updateBookmark({
    required int bookmarkId,
    String? memo,
  }) async {
    final response = await _dio.patch(
      '/api/bookmarks/$bookmarkId',
      data: {
        'memo': memo?.trim(),
      },
    );

    return Bookmark.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> deleteBookmark(int bookmarkId) async {
    await _dio.delete('/api/bookmarks/$bookmarkId');
  }
}