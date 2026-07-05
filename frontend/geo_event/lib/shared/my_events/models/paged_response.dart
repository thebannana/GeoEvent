class PagedResponse<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;

  const PagedResponse({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  bool get hasMore => (page * pageSize) < totalCount;
}