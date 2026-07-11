import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/application/auth_controller.dart';
import '../data/bookmark_repository.dart';
import '../models/bookmark.dart';
import '../models/paged_list_state.dart';
import '../providers/bookmark_providers.dart';

final bookmarksProvider =
    StateNotifierProvider<BookmarksController, PagedListState<Bookmark>>((ref) {
  ref.watch(sessionUserIdProvider);
  return BookmarksController(ref.read(bookmarkRepositoryProvider));
});

class BookmarksController extends StateNotifier<PagedListState<Bookmark>> {
  BookmarksController(this.repository) : super(const PagedListState<Bookmark>());

  final BookmarkRepository repository;
  String _query = '';
  int _requestId = 0;

  List<Bookmark> _sort(Iterable<Bookmark> items) {
    final list = items.toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return List.unmodifiable(list);
  }

  String? _normalizeQuery(String query) {
    final trimmed = query.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> loadInitial({String query = '', bool force = false}) async {
    if (state.loadedInitial && !force && _query == query.trim()) return;
    _query = query.trim();
    await _loadPage(reset: true);
  }

  Future<void> search(String query) async {
    _query = query.trim();
    await _loadPage(reset: true);
  }

  Future<void> refresh() async {
    await _loadPage(reset: true);
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;
    await _loadPage(reset: false);
  }

  Future<void> _loadPage({required bool reset}) async {
    final requestId = ++_requestId;
    final nextPage = reset ? 1 : state.page + 1;

    state = state.copyWith(
      loading: reset,
      loadingMore: !reset,
      clearError: true,
    );

    try {
      final result = await repository.getBookmarksPaged(
        searchTerm: _normalizeQuery(_query),
        page: nextPage,
        pageSize: state.pageSize,
      );

      if (requestId != _requestId) return;

      final merged = reset
          ? _sort(result.items)
          : _sort([...state.items, ...result.items]);

      state = state.copyWith(
        items: merged,
        loading: false,
        loadingMore: false,
        loadedInitial: true,
        page: result.page,
        pageSize: result.pageSize,
        totalCount: result.totalCount,
        hasMore: result.hasNextPage ||
            ((result.page * result.pageSize) < result.totalCount),
      );
    } catch (e) {
      if (requestId != _requestId) return;

      state = state.copyWith(
        items: reset ? const [] : state.items,
        loading: false,
        loadingMore: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  bool isBookmarked(int eventId) {
    return state.items.any((b) => b.eventId == eventId);
  }

  Bookmark? bookmarkForEvent(int eventId) {
    for (final bookmark in state.items) {
      if (bookmark.eventId == eventId) return bookmark;
    }
    return null;
  }

  Future<Bookmark?> addBookmark({
    required int eventId,
    String? memo,
  }) async {
    final existing = bookmarkForEvent(eventId);
    if (existing != null) return existing;

    final created = await repository.createBookmark(
      eventId: eventId,
      memo: memo?.trim().isEmpty == true ? null : memo?.trim(),
    );

    final existingWithoutDuplicate = state.items
        .where((b) => b.bookmarkId != created.bookmarkId && b.eventId != eventId)
        .toList(growable: false);

    final updated = _sort([created, ...existingWithoutDuplicate]);

    state = state.copyWith(
      items: updated,
      totalCount: updated.length > state.totalCount
          ? updated.length
          : state.totalCount + 1,
      loadedInitial: true,
    );

    return created;
  }

  Future<Bookmark?> updateMemo({
    required int bookmarkId,
    String? memo,
  }) async {
    final index = state.items.indexWhere((b) => b.bookmarkId == bookmarkId);
    if (index == -1) return null;

    final normalizedMemo = memo?.trim().isEmpty == true ? null : memo?.trim();
    final previous = state.items[index];

    final optimistic = previous.copyWith(
      memo: normalizedMemo,
      clearMemo: normalizedMemo == null,
    );

    final optimisticItems = [...state.items];
    optimisticItems[index] = optimistic;

    state = state.copyWith(items: List.unmodifiable(optimisticItems));

    try {
      final updated = await repository.updateBookmark(
        bookmarkId: bookmarkId,
        memo: normalizedMemo,
      );

      final confirmed = [...state.items];
      final confirmedIndex =
          confirmed.indexWhere((b) => b.bookmarkId == bookmarkId);

      if (confirmedIndex != -1) {
        confirmed[confirmedIndex] = updated;
      }

      state = state.copyWith(items: _sort(confirmed));
      return updated;
    } catch (_) {
      final rollback = [...state.items];
      final rollbackIndex =
          rollback.indexWhere((b) => b.bookmarkId == bookmarkId);

      if (rollbackIndex != -1) {
        rollback[rollbackIndex] = previous;
      }

      state = state.copyWith(items: List.unmodifiable(rollback));
      rethrow;
    }
  }

  Future<void> deleteBookmark(int bookmarkId) async {
    final snapshot = state.items;
    final previousTotalCount = state.totalCount;

    final updated =
        snapshot.where((b) => b.bookmarkId != bookmarkId).toList(growable: false);

    state = state.copyWith(
      items: List.unmodifiable(updated),
      totalCount: previousTotalCount > 0 ? previousTotalCount - 1 : 0,
      loadedInitial: true,
    );

    try {
      await repository.deleteBookmark(bookmarkId);
    } catch (_) {
      state = state.copyWith(
        items: List.unmodifiable(snapshot),
        totalCount: previousTotalCount,
      );
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
    final existing = bookmarkForEvent(eventId);

    if (existing != null) {
      await deleteBookmark(existing.bookmarkId);
      return;
    }

    try {
      await addBookmark(eventId: eventId, memo: memo);
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('already bookmarked') || message.contains('409')) {
        await refresh();
        final resolved = bookmarkForEvent(eventId);
        if (resolved != null) {
          return;
        }
      }
      rethrow;
    }
  }
}