import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/application/auth_controller.dart';
import '../data/bookmark_api.dart';
import '../data/bookmark_repository.dart';
import '../models/bookmark.dart';

final bookmarkApiProvider = Provider<BookmarkApi>((ref) {
  return BookmarkApi(ref.watch(authorizedDioProvider));
});

final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  return BookmarkRepository(ref.watch(bookmarkApiProvider));
});

final bookmarksProvider =
    AsyncNotifierProvider<BookmarksController, List<Bookmark>>(
  BookmarksController.new,
);

class BookmarksController extends AsyncNotifier<List<Bookmark>> {
  BookmarkRepository get _repository =>
      ref.read(bookmarkRepositoryProvider);

  @override
  Future<List<Bookmark>> build() async {
    return _repository.getBookmarks();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.getBookmarks);
  }

  Future<void> deleteBookmark(int bookmarkId) async {
    await _repository.deleteBookmark(bookmarkId);
    // Optimistically remove from state
    state.whenData((list) {
      state = AsyncData(
          list.where((b) => b.bookmarkId != bookmarkId).toList());
    });
  }
}