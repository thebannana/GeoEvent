class GetMyReportsRequest {
  static const int defaultPage = 1;
  static const int defaultPageSize = 10;
  static const int maxPageSize = 100;

  final int page;
  final int pageSize;

  const GetMyReportsRequest({
    this.page = defaultPage,
    this.pageSize = defaultPageSize,
  });

  GetMyReportsRequest copyWith({
    int? page,
    int? pageSize,
  }) {
    return GetMyReportsRequest(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  Map<String, dynamic> toQuery() {
    final normalizedPage = page < 1 ? defaultPage : page;
    final normalizedPageSize = pageSize < 1
        ? defaultPageSize
        : (pageSize > maxPageSize ? maxPageSize : pageSize);

    return {
      'page': normalizedPage,
      'pageSize': normalizedPageSize,
    };
  }
}