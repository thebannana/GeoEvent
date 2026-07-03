class PagedResult<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const PagedResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    final rawItems = json['items'] ?? json['Items'] ?? const [];

    return PagedResult<T>(
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((e) => fromItem(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      totalCount: _asInt(json['totalCount'] ?? json['TotalCount']),
      page: _asInt(json['page'] ?? json['Page'], fallback: 1),
      pageSize: _asInt(json['pageSize'] ?? json['PageSize'], fallback: 20),
      totalPages: _asInt(json['totalPages'] ?? json['TotalPages'], fallback: 1),
      hasNextPage: _asBool(json['hasNextPage'] ?? json['HasNextPage']),
      hasPreviousPage:
          _asBool(json['hasPreviousPage'] ?? json['HasPreviousPage']),
    );
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  static bool _asBool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.trim().toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    return fallback;
  }
}