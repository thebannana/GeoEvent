class PagedResult<T> {
  const PagedResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final rawItems = (json['items'] ?? json['Items'] ?? []) as List<dynamic>;

    final page = (json['page'] as num?)?.toInt() ?? 1;
    final pageSize = (json['pageSize'] as num?)?.toInt() ?? rawItems.length;
    final totalCount = (json['totalCount'] as num?)?.toInt() ?? rawItems.length;
    final totalPages = (json['totalPages'] as num?)?.toInt() ??
        (pageSize <= 0 ? 1 : (totalCount / pageSize).ceil());

    return PagedResult<T>(
      items: rawItems
          .whereType<Map>()
          .map((e) => fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      totalCount: totalCount,
      page: page,
      pageSize: pageSize,
      totalPages: totalPages,
      hasNextPage: json['hasNextPage'] as bool? ?? page < totalPages,
      hasPreviousPage: json['hasPreviousPage'] as bool? ?? page > 1,
    );
  }

  factory PagedResult.empty({int page = 1, int pageSize = 20}) {
    return PagedResult<T>(
      items: const [],
      totalCount: 0,
      page: page,
      pageSize: pageSize,
      totalPages: 0,
      hasNextPage: false,
      hasPreviousPage: false,
    );
  }
}