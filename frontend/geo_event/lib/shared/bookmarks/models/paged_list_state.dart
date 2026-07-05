class PagedListState<T> {
  final List<T> items;
  final bool loading;
  final bool loadingMore;
  final String? error;
  final int page;
  final int pageSize;
  final int totalCount;
  final bool hasMore;
  final bool loadedInitial;

  const PagedListState({
    this.items = const [],
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.page = 1,
    this.pageSize = 20,
    this.totalCount = 0,
    this.hasMore = true,
    this.loadedInitial = false,
  });

  PagedListState<T> copyWith({
    List<T>? items,
    bool? loading,
    bool? loadingMore,
    String? error,
    bool clearError = false,
    int? page,
    int? pageSize,
    int? totalCount,
    bool? hasMore,
    bool? loadedInitial,
  }) {
    return PagedListState<T>(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: clearError ? null : (error ?? this.error),
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      loadedInitial: loadedInitial ?? this.loadedInitial,
    );
  }
}