import '../models/bookmark.dart';
import 'bookmark_api.dart';

class BookmarkRepository {
  const BookmarkRepository(this._api);

  final BookmarkApi _api;

  Future<List<Bookmark>> getBookmarks() => _api.getBookmarks();

  Future<Bookmark> createBookmark({
    required int eventId,
    String? memo,
  }) {
    return _api.createBookmark(
      eventId: eventId,
      memo: memo,
    );
  }

  Future<Bookmark> updateBookmark({
    required int bookmarkId,
    String? memo,
  }) {
    return _api.updateBookmark(
      bookmarkId: bookmarkId,
      memo: memo,
    );
  }

  Future<void> deleteBookmark(int bookmarkId) {
    return _api.deleteBookmark(bookmarkId);
  }
}