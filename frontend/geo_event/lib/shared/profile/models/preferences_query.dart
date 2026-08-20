class PreferencesQuery {
  const PreferencesQuery({
    this.page = 1,
    this.pageSize = 20,
    this.type,
    this.minScore,
    this.maxScore,
  });

  final int page;
  final int pageSize;
  final String? type;
  final double? minScore;
  final double? maxScore;

  PreferencesQuery copyWith({
    int? page,
    int? pageSize,
    String? type,
    double? minScore,
    double? maxScore,
    bool clearType = false,
    bool clearMinScore = false,
    bool clearMaxScore = false,
  }) {
    return PreferencesQuery(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      type: clearType ? null : (type ?? this.type),
      minScore: clearMinScore ? null : (minScore ?? this.minScore),
      maxScore: clearMaxScore ? null : (maxScore ?? this.maxScore),
    );
  }

  Map<String, dynamic> toQueryParameters() {
    return {
      'page': page,
      'pageSize': pageSize,
      if (type != null && type!.trim().isNotEmpty) 'type': type!.trim(),
      if (minScore != null) 'minScore': minScore,
      if (maxScore != null) 'maxScore': maxScore,
    };
  }
}