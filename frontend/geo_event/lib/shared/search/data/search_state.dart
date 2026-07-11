import '../../../../shared/events/models/create_event_models.dart';
import '../models/filter_selection.dart';
import '../models/sort_option.dart';

class SearchState {
  final String query;
  final List<EventItem> results;
  final bool loading;
  final bool loadingMore;
  final String? error;
  final bool loadedInitial;
  final FilterSelection filter;
  final SortOption sort;
  final int page;
  final int pageSize;
  final int totalCount;
  final bool hasMore;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.loadedInitial = false,
    this.filter = FilterSelection.empty,
    this.sort = SortOption.soonest,
    this.page = 1,
    this.pageSize = 20,
    this.totalCount = 0,
    this.hasMore = true,
  });

  bool get hasQuery => query.trim().isNotEmpty;
  bool get hasActiveFilters => filter.hasActive;
  bool get isEmpty => !loading && error == null && results.isEmpty;

  SearchState copyWith({
    String? query,
    List<EventItem>? results,
    bool? loading,
    bool? loadingMore,
    String? error,
    bool clearError = false,
    bool? loadedInitial,
    FilterSelection? filter,
    SortOption? sort,
    int? page,
    int? pageSize,
    int? totalCount,
    bool? hasMore,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: clearError ? null : (error ?? this.error),
      loadedInitial: loadedInitial ?? this.loadedInitial,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}