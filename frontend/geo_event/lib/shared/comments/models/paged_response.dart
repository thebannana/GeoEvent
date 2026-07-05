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

  int get totalPages =>
      pageSize <= 0 ? 0 : ((totalCount + pageSize - 1) ~/ pageSize);

  bool get hasNextPage => page < totalPages;

  factory PagedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((e) => fromItem(Map<String, dynamic>.from(e)))
            .toList(growable: false)
        : <T>[];

    return PagedResponse<T>(
      items: items,
      totalCount: _asInt(json['totalCount']),
      page: _asInt(json['page'], fallback: 1),
      pageSize: _asInt(json['pageSize'], fallback: items.isEmpty ? 20 : items.length),
    );
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}