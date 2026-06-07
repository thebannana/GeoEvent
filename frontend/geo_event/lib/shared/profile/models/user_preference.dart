class UserPreference {
  final int prefId;
  final int? segmentId;
  final int? genreId;
  final double score;
  final DateTime lastUpdated;

  const UserPreference({
    required this.prefId,
    this.segmentId,
    this.genreId,
    required this.score,
    required this.lastUpdated,
  });

  factory UserPreference.fromJson(Map<String, dynamic> json) {
    return UserPreference(
      prefId: (json['prefId'] as num).toInt(),
      segmentId: (json['segmentId'] as num?)?.toInt(),
      genreId: (json['genreId'] as num?)?.toInt(),
      score: (json['score'] as num?)?.toDouble() ?? 0,
      lastUpdated: DateTime.parse((json['lastUpdated'] ?? '').toString()),
    );
  }
}