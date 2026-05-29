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

  factory UserPreference.fromJson(Map<String, dynamic> json) => UserPreference(
        prefId: json['prefId'] as int,
        segmentId: json['segmentId'] as int?,
        genreId: json['genreId'] as int?,
        score: (json['score'] as num).toDouble(),
        lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      );
}