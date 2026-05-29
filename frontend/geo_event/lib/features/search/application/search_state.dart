import '../../../../shared/events/models/create_event_models.dart';
import '../domain/filter_selection.dart';
import '../domain/sort_option.dart';

class SearchState {
  final String query;
  final List<EventItem> results;
  final bool loading;
  final String? error;
  final bool loadedInitial;
  final FilterSelection filter;
  final SortOption sort;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.loading = false,
    this.error,
    this.loadedInitial = false,
    this.filter = FilterSelection.empty,
    this.sort = SortOption.soonest,
  });

  bool get hasQuery => query.trim().isNotEmpty;
  bool get hasActiveFilters => filter.hasActive;

  SearchState copyWith({
    String? query,
    List<EventItem>? results,
    bool? loading,
    String? error,
    bool clearError = false,
    bool? loadedInitial,
    FilterSelection? filter,
    SortOption? sort,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      loadedInitial: loadedInitial ?? this.loadedInitial,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
    );
  }
}