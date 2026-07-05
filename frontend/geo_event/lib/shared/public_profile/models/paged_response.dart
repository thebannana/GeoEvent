class PagedResponse<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const PagedResponse({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory PagedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((e) => fromItem(Map<String, dynamic>.from(e)))
            .toList()
        : <T>[];

    final totalCount = (json['totalCount'] as num?)?.toInt() ?? items.length;
    final page = (json['page'] as num?)?.toInt() ?? 1;
    final pageSize = (json['pageSize'] as num?)?.toInt() ?? items.length;
    final totalPages = (json['totalPages'] as num?)?.toInt() ??
        (pageSize > 0 ? (totalCount / pageSize).ceil() : 1);

    return PagedResponse<T>(
      items: items,
      totalCount: totalCount,
      page: page,
      pageSize: pageSize,
      totalPages: totalPages,
      hasNextPage: json['hasNextPage'] == true,
      hasPreviousPage: json['hasPreviousPage'] == true,
    );
  }
}