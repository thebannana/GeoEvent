import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/events/models/create_event_models.dart';
import '../../../../shared/events/models/paged_result.dart';
import '../../../../shared/profile/models/user_preference.dart';
import '../../../shared/events/providers/event_providers.dart';
import '../../profile/application/preferences_controller.dart';
import '../../../shared/search/models/filter_selection.dart';
import '../../../shared/search/models/sort_option.dart';
import '../../../shared/search/data/search_state.dart';

final searchControllerProvider =
    StateNotifierProvider.autoDispose<SearchController, SearchState>((ref) {
  return SearchController(ref);
});

class SearchController extends StateNotifier<SearchState> {
  SearchController(this.ref) : super(const SearchState());

  final Ref ref;
  int _requestId = 0;

  Map<int, double> _segmentWeights(List<UserPreference> preferences) {
    final map = <int, double>{};

    for (final pref in preferences) {
      final segmentId = pref.segmentId;
      if (segmentId != null) {
        map[segmentId] = (map[segmentId] ?? 0) + pref.score;
      }
    }

    return map;
  }

  Map<int, double> _genreWeights(List<UserPreference> preferences) {
    final map = <int, double>{};

    for (final pref in preferences) {
      final genreId = pref.genreId;
      if (genreId != null) {
        map[genreId] = (map[genreId] ?? 0) + pref.score;
      }
    }

    return map;
  }

  List<UserPreference> _preferences() {
    return ref.read(preferencesControllerProvider).maybeWhen(
          data: (value) => value.result.items,
          orElse: () => <UserPreference>[],
        );
  }

  double _preferenceScore(
    EventItem item,
    Map<int, double> segmentWeights,
    Map<int, double> genreWeights,
  ) {
    var score = 0.0;

    if (item.segmentId != null) {
      score += (segmentWeights[item.segmentId!] ?? 0) * 30;
    }

    if (item.genreId != null) {
      score += (genreWeights[item.genreId!] ?? 0) * 22;
    }

    if (item.isFeatured) {
      score += 6;
    }

    return score;
  }

  double _basePopularityScore(EventItem item) {
    return (item.likesCount / 20) + (item.viewCount / 200);
  }

  double _searchTextScore(EventItem item, String query) {
    final q = query.toLowerCase();
    var total = 0.0;

    final title = item.title.toLowerCase();
    final description = item.description.toLowerCase();
    final segment = (item.segmentName ?? '').toLowerCase();
    final genre = (item.genreName ?? '').toLowerCase();
    final subGenre = (item.subGenreName ?? '').toLowerCase();
    final tags = (item.tags ?? '').toLowerCase();
    final promoter = (item.promoterName ?? '').toLowerCase();

    if (title.contains(q)) total += 90;
    if (description.contains(q)) total += 30;
    if (segment.contains(q)) total += 28;
    if (genre.contains(q)) total += 24;
    if (subGenre.contains(q)) total += 20;
    if (tags.contains(q)) total += 18;
    if (promoter.contains(q)) total += 14;

    return total;
  }

  List<EventItem> _rankItems(
    List<EventItem> items, {
    required String query,
    required List<UserPreference> preferences,
  }) {
    final segmentWeights = _segmentWeights(preferences);
    final genreWeights = _genreWeights(preferences);
    final trimmed = query.trim();

    double score(EventItem item) {
      var total = 0.0;
      total += _preferenceScore(item, segmentWeights, genreWeights);
      total += _basePopularityScore(item);

      if (trimmed.isNotEmpty) {
        total += _searchTextScore(item, trimmed);
      }

      return total;
    }

    final ranked = [...items]..sort((a, b) => score(b).compareTo(score(a)));
    return ranked;
  }

  Future<void> loadInitial({bool force = false}) async {
    if (state.loadedInitial && !force) return;
    await _loadPage(reset: true, queryOverride: state.query);
  }

  Future<void> search(String query) async {
    state = state.copyWith(query: query);
    await _loadPage(reset: true, queryOverride: query);
  }

  Future<void> clearQuery() async {
    state = state.copyWith(query: '');
    await _loadPage(reset: true, queryOverride: '');
  }

  Future<void> applySort(SortOption option) async {
    state = state.copyWith(sort: option);
    await _loadPage(reset: true, queryOverride: state.query);
  }

  Future<void> applyFilter(FilterSelection filter) async {
    state = state.copyWith(filter: filter);
    await _loadPage(reset: true, queryOverride: state.query);
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;
    await _loadPage(reset: false, queryOverride: state.query);
  }

  Future<void> _loadPage({
    required bool reset,
    required String queryOverride,
  }) async {
    final trimmed = queryOverride.trim();
    final requestId = ++_requestId;
    final nextPage = reset ? 1 : state.page + 1;

    state = state.copyWith(
      query: queryOverride,
      loading: reset,
      loadingMore: !reset,
      clearError: true,
    );

    try {
      final PagedResult<EventItem> result =
          await ref.read(eventsRepositoryProvider).searchEventsPaged(
                searchTerm: trimmed.isEmpty ? null : trimmed,
                page: nextPage,
                pageSize: state.pageSize,
                sortBy: state.sort.sortBy,
                sortDescending: state.sort.sortDescending,
                segmentId: state.filter.segmentId,
                genreId: state.filter.genreId,
                subGenreId: state.filter.subGenreId,
              );

      if (!mounted || requestId != _requestId) return;

      var pageItems = result.items.where((item) => item.isVisibleInSearch).toList();

      if (state.sort.isClientSideRanked) {
        pageItems = _rankItems(
          pageItems,
          query: trimmed,
          preferences: _preferences(),
        );
      }

      final merged = reset ? pageItems : [...state.results, ...pageItems];

      state = state.copyWith(
        query: queryOverride,
        results: merged,
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
      if (!mounted || requestId != _requestId) return;

      state = state.copyWith(
        query: queryOverride,
        results: reset ? const [] : state.results,
        loading: false,
        loadingMore: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}