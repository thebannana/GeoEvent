import '../../events/models/paged_result.dart';
import '../models/bookmark.dart';
import 'bookmark_api.dart';

class BookmarkRepository {
  const BookmarkRepository(this.api);

  final BookmarkApi api;

  Future<PagedResult<Bookmark>> getBookmarksPaged({
    String? searchTerm,
    int page = 1,
    int pageSize = 20,
  }) {
    return api.getBookmarksPaged(
      searchTerm: searchTerm,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<Bookmark> createBookmark({
    required int eventId,
    String? memo,
  }) {
    return api.createBookmark(
      eventId: eventId,
      memo: memo,
    );
  }

  Future<Bookmark> updateBookmark({
    required int bookmarkId,
    String? memo,
  }) {
    return api.updateBookmark(
      bookmarkId: bookmarkId,
      memo: memo,
    );
  }

  Future<void> deleteBookmark(int bookmarkId) {
    return api.deleteBookmark(bookmarkId);
  }
}