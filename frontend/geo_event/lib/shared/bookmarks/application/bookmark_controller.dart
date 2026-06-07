import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/bookmark_repository.dart';
import '../models/bookmark.dart';
import '../providers/bookmark_providers.dart';

class BookmarksController extends AsyncNotifier<List<Bookmark>> {
  BookmarkRepository get _repository => ref.read(bookmarkRepositoryProvider);

  @override
  Future<List<Bookmark>> build() async {
    return _repository.getBookmarks();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.getBookmarks);
  }

  bool isBookmarked(int eventId) {
    final bookmarks = state.valueOrNull ?? const <Bookmark>[];
    return bookmarks.any((b) => b.eventId == eventId);
  }

  Bookmark? bookmarkForEvent(int eventId) {
    final bookmarks = state.valueOrNull ?? const <Bookmark>[];
    for (final bookmark in bookmarks) {
      if (bookmark.eventId == eventId) return bookmark;
    }
    return null;
  }

  Future<Bookmark?> addBookmark({
    required int eventId,
    String? memo,
  }) async {
    final current = state.valueOrNull ?? const <Bookmark>[];

    final existing = current.cast<Bookmark?>().firstWhere(
          (b) => b?.eventId == eventId,
          orElse: () => null,
        );

    if (existing != null) {
      return existing;
    }

    final created = await _repository.createBookmark(
      eventId: eventId,
      memo: memo,
    );

    final updated = [created, ...current];
    updated.sort((a, b) => b.savedAt.compareTo(a.savedAt));

    state = AsyncData(updated);
    return created;
  }

  Future<Bookmark?> updateMemo({
    required int bookmarkId,
    String? memo,
  }) async {
    final current = state.valueOrNull ?? const <Bookmark>[];

    final index = current.indexWhere((b) => b.bookmarkId == bookmarkId);
    if (index == -1) return null;

    final previousBookmark = current[index];
    final optimisticBookmark = previousBookmark.copyWith(
      memo: memo?.trim(),
      clearMemo: memo == null,
    );

    final optimisticList = [...current];
    optimisticList[index] = optimisticBookmark;
    state = AsyncData(optimisticList);

    try {
      final updated = await _repository.updateBookmark(
        bookmarkId: bookmarkId,
        memo: memo,
      );

      final confirmedList = [...optimisticList];
      final confirmedIndex =
          confirmedList.indexWhere((b) => b.bookmarkId == bookmarkId);

      if (confirmedIndex != -1) {
        confirmedList[confirmedIndex] = updated;
        state = AsyncData(confirmedList);
      }

      return updated;
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> deleteBookmark(int bookmarkId) async {
    final current = state.valueOrNull ?? const <Bookmark>[];

    final updated =
        current.where((b) => b.bookmarkId != bookmarkId).toList(growable: false);

    state = AsyncData(updated);

    try {
      await _repository.deleteBookmark(bookmarkId);
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> removeBookmarkByEventId(int eventId) async {
    final bookmark = bookmarkForEvent(eventId);
    if (bookmark == null) return;

    await deleteBookmark(bookmark.bookmarkId);
  }

  Future<void> toggleBookmark({required int eventId}) async {
  final current = state.valueOrNull ?? const <Bookmark>[];

  final index = current.indexWhere((b) => b.eventId == eventId);

  if (index != -1) {
    final bookmark = current[index];
    final updated =
        current.where((b) => b.bookmarkId != bookmark.bookmarkId).toList();

    state = AsyncData(updated);

    try {
      await _repository.deleteBookmark(bookmark.bookmarkId);
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
    return;
  }

  final optimistic = Bookmark(
    bookmarkId: -eventId,
    eventId: eventId,
    userId: null,
    memo: null,
    imageUrl: '',
    savedAt: DateTime.now(),
  );

  final optimisticList = [optimistic, ...current];
  optimisticList.sort((a, b) => b.savedAt.compareTo(a.savedAt));
  state = AsyncData(optimisticList);

  try {
    final created = await _repository.createBookmark(eventId: eventId);

final confirmed = [
  for (final bookmark in optimisticList)
    if (bookmark.bookmarkId == -eventId && bookmark.eventId == eventId)
      created
    else
      bookmark,
];

    confirmed.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    state = AsyncData(confirmed);
  } catch (_) {
    state = AsyncData(current);
    rethrow;
  }
}
}