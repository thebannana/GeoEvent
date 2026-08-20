import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/events/models/create_event_models.dart';
import '../../../../shared/events/models/paged_result.dart';
import '../../../../shared/profile/models/user_preference.dart';
import '../../../shared/events/models/recommendation_scoring.dart';
import '../../../shared/events/providers/event_providers.dart';
import '../../profile/application/preferences_controller.dart';
import '../../../shared/search/models/filter_selection.dart';
import '../../../shared/search/models/sort_option.dart';
import '../../../shared/search/data/search_state.dart';
import '../../../../shared/location/data/map_location_service.dart';

final searchControllerProvider =
    StateNotifierProvider.autoDispose<SearchController, SearchState>((ref) {
  return SearchController(ref);
});

class SearchController extends StateNotifier<SearchState> {
  SearchController(this.ref) : super(const SearchState());

  final Ref ref;
  final _locationService = MapLocationService();

  int _requestId = 0;

  List<UserPreference> _preferences() {
    return ref.read(preferencesControllerProvider).maybeWhen(
          data: (value) => value.result.items,
          orElse: () => <UserPreference>[],
        );
  }

  Future<({double latitude, double longitude})> _getUserLocation() async {
    try {
      final result = await _locationService.getCurrentLocation();
      if (result.position != null) {
        return (
          latitude: result.position!.latitude,
          longitude: result.position!.longitude,
        );
      }
    } catch (_) {
      // Ignore location errors; fallback to default.
    }

    return (latitude: 43.8563, longitude: 18.4131);
  }

  Future<List<EventItem>> _rankItems(
    List<EventItem> items, {
    required String query,
    required List<UserPreference> preferences,
  }) async {
    final userLocation = await _getUserLocation();

    final preferredSegmentIds = preferences
        .where((preference) => preference.segmentId != null)
        .map((preference) => preference.segmentId!)
        .toSet();

    final preferredGenreIds = preferences
        .where((preference) => preference.genreId != null)
        .map((preference) => preference.genreId!)
        .toSet();

    final preferredSubGenreIds = preferences
        .where((preference) => preference.subGenreId != null)
        .map((preference) => preference.subGenreId!)
        .toSet();

    double score(EventItem item) {
      return RecommendationScorer.score(
        item: item,
        userLatitude: userLocation.latitude,
        userLongitude: userLocation.longitude,
        preferredSegmentIds: preferredSegmentIds,
        preferredGenreIds: preferredGenreIds,
        preferredSubGenreIds: preferredSubGenreIds,
        query: query,
      ).total;
    }

    final ranked = [...items]
      ..sort((a, b) => score(b).compareTo(score(a)));

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
                pageSize: state.sort.isClientSideRanked ? 100 : state.pageSize,
                sortBy: state.sort.sortBy,
                sortDescending: state.sort.sortDescending,
                segmentId: state.filter.segmentId,
                genreId: state.filter.genreId,
                subGenreId: state.filter.subGenreId,
              );

      if (!mounted || requestId != _requestId) return;

      var pageItems = result.items
          .where((item) => item.isVisibleInSearch)
          .toList();

      if (state.sort.isClientSideRanked) {
        pageItems = await _rankItems(
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