import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/application/auth_controller.dart';
import '../data/bookmark_repository.dart';
import '../models/bookmark.dart';
import '../providers/bookmark_providers.dart';

class BookmarksController extends AsyncNotifier<List<Bookmark>> {
  BookmarkRepository get _repository => ref.read(bookmarkRepositoryProvider);

  @override
  Future<List<Bookmark>> build() async {
    ref.watch(sessionUserIdProvider);
    return _loadBookmarks();
  }

  Future<List<Bookmark>> _loadBookmarks() async {
    final items = await _repository.getBookmarks();
    return _sort(items);
  }

  List<Bookmark> _current() => state.valueOrNull ?? const <Bookmark>[];

  List<Bookmark> _sort(Iterable<Bookmark> items) {
    final list = items.toList()..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return List.unmodifiable(list);
  }

  String? _normalizeMemo(String? memo) {
    final trimmed = memo?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadBookmarks);
  }

  bool isBookmarked(int eventId) {
    return _current().any((b) => b.eventId == eventId);
  }

  Bookmark? bookmarkForEvent(int eventId) {
    for (final bookmark in _current()) {
      if (bookmark.eventId == eventId) return bookmark;
    }
    return null;
  }

  Future<Bookmark?> addBookmark({
    required int eventId,
    String? memo,
  }) async {
    final snapshot = _current();
    final existing = bookmarkForEvent(eventId);
    if (existing != null) return existing;

    final created = await _repository.createBookmark(
      eventId: eventId,
      memo: _normalizeMemo(memo),
    );

    state = AsyncData(_sort([created, ...snapshot]));
    return created;
  }

  Future<Bookmark?> updateMemo({
    required int bookmarkId,
    String? memo,
  }) async {
    final snapshot = _current();
    final index = snapshot.indexWhere((b) => b.bookmarkId == bookmarkId);
    if (index == -1) return null;

    final normalizedMemo = _normalizeMemo(memo);
    final previousBookmark = snapshot[index];

    final optimisticBookmark = previousBookmark.copyWith(
      memo: normalizedMemo,
      clearMemo: normalizedMemo == null,
    );

    final optimisticList = [...snapshot];
    optimisticList[index] = optimisticBookmark;
    state = AsyncData(List.unmodifiable(optimisticList));

    try {
      final updated = await _repository.updateBookmark(
        bookmarkId: bookmarkId,
        memo: normalizedMemo,
      );

      final confirmedList = [...optimisticList];
      final confirmedIndex =
          confirmedList.indexWhere((b) => b.bookmarkId == bookmarkId);

      if (confirmedIndex != -1) {
        confirmedList[confirmedIndex] = updated;
      }

      state = AsyncData(_sort(confirmedList));
      return updated;
    } catch (_) {
      state = AsyncData(List.unmodifiable(snapshot));
      rethrow;
    }
  }

  Future<void> deleteBookmark(int bookmarkId) async {
    final snapshot = _current();

    final updated = snapshot
        .where((b) => b.bookmarkId != bookmarkId)
        .toList(growable: false);

    state = AsyncData(List.unmodifiable(updated));

    try {
      await _repository.deleteBookmark(bookmarkId);
    } catch (_) {
      state = AsyncData(List.unmodifiable(snapshot));
      rethrow;
    }
  }

  Future<void> removeBookmarkByEventId(int eventId) async {
    final bookmark = bookmarkForEvent(eventId);
    if (bookmark == null) return;

    await deleteBookmark(bookmark.bookmarkId);
  }

  Future<void> toggleBookmark({
    required int eventId,
    String? memo,
  }) async {
    final snapshot = _current();
    final existing = bookmarkForEvent(eventId);

    if (existing != null) {
      final updated = snapshot
          .where((b) => b.bookmarkId != existing.bookmarkId)
          .toList(growable: false);

      state = AsyncData(List.unmodifiable(updated));

      try {
        await _repository.deleteBookmark(existing.bookmarkId);
      } catch (_) {
        state = AsyncData(List.unmodifiable(snapshot));
        rethrow;
      }
      return;
    }

    final optimistic = Bookmark(
      bookmarkId: -eventId,
      eventId: eventId,
      userId: null,
      title: 'Saved event',
      imageUrl: '',
      memo: _normalizeMemo(memo),
      savedAt: DateTime.now(),
    );

    final optimisticList = _sort([optimistic, ...snapshot]);
    state = AsyncData(optimisticList);

    try {
      final created = await _repository.createBookmark(
        eventId: eventId,
        memo: _normalizeMemo(memo),
      );

      final confirmed = [
        for (final bookmark in optimisticList)
          if (bookmark.bookmarkId == optimistic.bookmarkId &&
              bookmark.eventId == optimistic.eventId)
            created
          else
            bookmark,
      ];

      state = AsyncData(_sort(confirmed));
    } catch (_) {
      state = AsyncData(List.unmodifiable(snapshot));
      rethrow;
    }
  }
}