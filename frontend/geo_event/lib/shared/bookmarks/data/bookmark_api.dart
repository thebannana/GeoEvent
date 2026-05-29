import 'package:dio/dio.dart';

import '../models/bookmark.dart';

class BookmarkApi {
  final Dio _dio;
  BookmarkApi(this._dio);

  Future<List<Bookmark>> getBookmarks() async {
    final response = await _dio.get('/api/bookmarks');
    final list = response.data as List<dynamic>;
    return list.map((e) => Bookmark.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> deleteBookmark(int bookmarkId) async {
    await _dio.delete('/api/bookmarks/$bookmarkId');
  }
}