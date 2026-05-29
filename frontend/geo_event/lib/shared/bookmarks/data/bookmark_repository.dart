import '../models/bookmark.dart';
import 'bookmark_api.dart';

class BookmarkRepository {
  final BookmarkApi _api;
  BookmarkRepository(this._api);

  Future<List<Bookmark>> getBookmarks() => _api.getBookmarks();

  Future<void> deleteBookmark(int bookmarkId) =>
      _api.deleteBookmark(bookmarkId);
}