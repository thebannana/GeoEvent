import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/events/models/create_event_models.dart';
import '../../../shared/events/providers/event_providers.dart';
import '../../../shared/search/data/search_state.dart';
import '../../../shared/search/models/filter_selection.dart';
import '../../../shared/search/models/sort_option.dart';

final searchControllerProvider =
    StateNotifierProvider.autoDispose<
        SearchController,
        SearchState>(
  (ref) => SearchController(ref),
);

class SearchController
    extends StateNotifier<SearchState> {
  SearchController(this.ref)
      : super(const SearchState());

  final Ref ref;

  int _requestId = 0;

  Future<void> loadInitial({
    bool force = false,
  }) async {
    if (state.loadedInitial && !force) {
      return;
    }

    await _loadPage(
      reset: true,
      queryOverride: state.query,
    );
  }

  Future<void> search(String query) async {
    state = state.copyWith(query: query);

    await _loadPage(
      reset: true,
      queryOverride: query,
    );
  }

  Future<void> clearQuery() async {
    state = state.copyWith(query: '');

    await _loadPage(
      reset: true,
      queryOverride: '',
    );
  }

  Future<void> applySort(
    SortOption option,
  ) async {
    state = state.copyWith(sort: option);

    await _loadPage(
      reset: true,
      queryOverride: state.query,
    );
  }

  Future<void> applyFilter(
    FilterSelection filter,
  ) async {
    state = state.copyWith(filter: filter);

    await _loadPage(
      reset: true,
      queryOverride: state.query,
    );
  }

  Future<void> loadMore() async {
    if (state.loading ||
        state.loadingMore ||
        !state.hasMore) {
      return;
    }

    await _loadPage(
      reset: false,
      queryOverride: state.query,
    );
  }

  void reset() {
    _requestId++;
    state = const SearchState();
  }

  Future<void> _loadPage({
    required bool reset,
    required String queryOverride,
  }) async {
    final requestId = ++_requestId;
    final trimmedQuery = queryOverride.trim();
    final nextPage = reset ? 1 : state.page + 1;

    final usePreferences =
        state.sort.isClientSideRanked;

    state = state.copyWith(
      query: queryOverride,
      loading: reset,
      loadingMore: !reset,
      clearError: true,
    );

    try {
      final result = await ref
          .read(eventsRepositoryProvider)
          .searchEventsPaged(
            searchTerm: trimmedQuery.isEmpty
                ? null
                : trimmedQuery,
            page: nextPage,
            pageSize: state.pageSize,
            sortBy: usePreferences
                ? ''
                : state.sort.sortBy,
            sortDescending: usePreferences
                ? true
                : state.sort.sortDescending,
            segmentId: state.filter.segmentId,
            genreId: state.filter.genreId,
            subGenreId: state.filter.subGenreId,
            usePreferences: usePreferences,
          );

      if (!mounted ||
          requestId != _requestId) {
        return;
      }

      final pageItems = result.items
          .where(
            (item) => item.isVisibleInSearch,
          )
          .toList();

      final mergedItems = reset
          ? pageItems
          : <EventItem>[
              ...state.results,
              ...pageItems,
            ];

      state = state.copyWith(
        query: queryOverride,
        results: mergedItems,
        loading: false,
        loadingMore: false,
        loadedInitial: true,
        page: result.page,
        pageSize: result.pageSize,
        totalCount: result.totalCount,
        hasMore: result.hasNextPage ||
            result.page * result.pageSize <
                result.totalCount,
      );
    } catch (error) {
      if (!mounted ||
          requestId != _requestId) {
        return;
      }

      state = state.copyWith(
        query: queryOverride,
        results: reset
            ? const <EventItem>[]
            : state.results,
        loading: false,
        loadingMore: false,
        error: error
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            ),
      );
    }
  }
}