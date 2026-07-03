class PagedResult<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  const PagedResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;

  factory PagedResult.fromJson(
    Map<String, dynamic> json, {
    required T Function(Object? item) fromJsonT,
  }) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];

    return PagedResult<T>(
      items: rawItems.map(fromJsonT).toList(),
      page: (json['page'] as num? ?? 1).toInt(),
      pageSize: (json['pageSize'] as num? ?? rawItems.length).toInt(),
      totalCount: (json['totalCount'] as num? ?? rawItems.length).toInt(),
      totalPages: (json['totalPages'] as num? ?? 1).toInt(),
    );
  }
}