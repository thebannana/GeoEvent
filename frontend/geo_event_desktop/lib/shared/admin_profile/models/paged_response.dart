class PagedResponse<T> {
  const PagedResponse({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;

  int get totalPages =>
      pageSize <= 0 ? 1 : (totalCount / pageSize).ceil().clamp(1, 999999);

  factory PagedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> item) fromJson,
  ) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .map((item) => fromJson(Map<String, dynamic>.from(item as Map)))
            .toList()
        : <T>[];

    return PagedResponse<T>(
      items: items,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? items.length,
    );
  }
}