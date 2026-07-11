import '../../../core/utils/date_time_extensions.dart';

class UserPreference {
  final int prefId;
  final int? segmentId;
  final int? genreId;
  final int? subGenreId;
  final double score;
  final DateTime lastUpdated;

  const UserPreference({
    required this.prefId,
    this.segmentId,
    this.genreId,
    this.subGenreId,
    required this.score,
    required this.lastUpdated,
  });

  factory UserPreference.fromJson(Map<String, dynamic> json) {
    return UserPreference(
      prefId: (json['prefId'] as num?)?.toInt() ?? 0,
      segmentId: (json['segmentId'] as num?)?.toInt(),
      genreId: (json['genreId'] as num?)?.toInt(),
      subGenreId: (json['subGenreId'] as num?)?.toInt(),
      score: (json['score'] as num?)?.toDouble() ?? 0,
      lastUpdated: (() {
        try {
          return parseApiDateTime(json['lastUpdated']);
        } catch (_) {
          return DateTime.fromMillisecondsSinceEpoch(0);
        }
      })(),
    );
  }
}