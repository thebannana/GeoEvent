import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/application/auth_controller.dart';
import '../../bookmarks/models/paged_list_state.dart';
import '../data/liked_events_api.dart';
import '../data/liked_events_repository.dart';
import '../models/liked_event.dart';

final likedEventsRepositoryProvider = Provider<LikedEventsRepository>((ref) {
  return LikedEventsRepository(ref.read(likedEventsApiProvider));
});

final likedEventsProvider =
    StateNotifierProvider<LikedEventsController, PagedListState<LikedEvent>>((ref) {
  ref.watch(sessionUserIdProvider);
  return LikedEventsController(ref.read(likedEventsRepositoryProvider));
});

class LikedEventsController extends StateNotifier<PagedListState<LikedEvent>> {
  LikedEventsController(this.repository)
      : super(const PagedListState<LikedEvent>());

  final LikedEventsRepository repository;
  int _requestId = 0;

  List<LikedEvent> _sort(Iterable<LikedEvent> items) {
    final list = items.toList()
      ..sort((a, b) => b.likedAt.compareTo(a.likedAt));
    return List.unmodifiable(list);
  }

  Future<void> loadInitial({bool force = false}) async {
    if (state.loadedInitial && !force) return;
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
      final result = await repository.getLikedEventsPaged(
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

  Future<void> likeEvent(int eventId) async {
    final alreadyLiked = state.items.any((e) => e.eventId == eventId);
    if (alreadyLiked) return;

    await repository.likeEvent(eventId);
    await refresh();
  }

  Future<void> unlikeEvent(int eventId) async {
    final snapshot = state.items;

    state = state.copyWith(
      items: List.unmodifiable(
        snapshot.where((e) => e.eventId != eventId).toList(),
      ),
      totalCount: state.totalCount > 0 ? state.totalCount - 1 : 0,
    );

    try {
      await repository.unlikeEvent(eventId);
    } catch (_) {
      state = state.copyWith(
        items: List.unmodifiable(snapshot),
        totalCount: state.totalCount + 1,
      );
      rethrow;
    }
  }
}