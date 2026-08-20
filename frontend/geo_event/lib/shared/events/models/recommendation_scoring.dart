import 'create_event_models.dart';

class RecommendationScoreBreakdown {
  final double preference;
  final double distance;
  final double popularity;
  final double featured;
  final double text;
  final double total;

  const RecommendationScoreBreakdown({
    required this.preference,
    required this.distance,
    required this.popularity,
    required this.featured,
    required this.text,
  }) : total = preference + distance + popularity + featured + text;

  int get roundedTotal => total.round();
}

class RecommendationScorer {
  const RecommendationScorer._();

  static const double segmentWeight = 30;
  static const double genreWeight = 22;
  static const double subGenreWeight = 16;

  static const double featuredWeight = 10;

  static const double maxDistanceKm = 25;

  static RecommendationScoreBreakdown score({
    required EventItem item,
    required double userLatitude,
    required double userLongitude,
    required Set<int> preferredSegmentIds,
    required Set<int> preferredGenreIds,
    required Set<int> preferredSubGenreIds,
    String query = '',
  }) {
    final preference = _preferenceScore(
      item: item,
      preferredSegmentIds: preferredSegmentIds,
      preferredGenreIds: preferredGenreIds,
      preferredSubGenreIds: preferredSubGenreIds,
    );

    final distance = _distanceScore(
      item: item,
      userLatitude: userLatitude,
      userLongitude: userLongitude,
    );

    final popularity = _popularityScore(item);

    final featured = item.isFeatured ? featuredWeight : 0.0;

    final text = query.trim().isEmpty
        ? 0.0
        : _textScore(item, query.trim());

    return RecommendationScoreBreakdown(
      preference: preference,
      distance: distance,
      popularity: popularity,
      featured: featured,
      text: text,
    );
  }

  static double _preferenceScore({
    required EventItem item,
    required Set<int> preferredSegmentIds,
    required Set<int> preferredGenreIds,
    required Set<int> preferredSubGenreIds,
  }) {
    var score = 0.0;

    if (item.segmentId != null &&
        preferredSegmentIds.contains(item.segmentId)) {
      score += segmentWeight;
    }

    if (item.genreId != null &&
        preferredGenreIds.contains(item.genreId)) {
      score += genreWeight;
    }

    if (item.subGenreId != null &&
        preferredSubGenreIds.contains(item.subGenreId)) {
      score += subGenreWeight;
    }

    return score;
  }

  static double _distanceScore({
    required EventItem item,
    required double userLatitude,
    required double userLongitude,
  }) {
    final distance = distanceKm(
      lat1: userLatitude,
      lon1: userLongitude,
      lat2: item.latitude,
      lon2: item.longitude,
    );

    if (distance <= 2) return 24;
    if (distance <= 5) return 16;
    if (distance <= 10) return 10;
    if (distance <= maxDistanceKm) return 4;

    return 0;
  }

  static double _popularityScore(EventItem item) {
    return (item.likesCount / 25) + (item.viewCount / 250);
  }

  static double _textScore(EventItem item, String query) {
    final q = query.toLowerCase();
    var score = 0.0;

    final title = item.title.toLowerCase();
    final description = item.description.toLowerCase();
    final segment = (item.segmentName ?? '').toLowerCase();
    final genre = (item.genreName ?? '').toLowerCase();
    final subGenre = (item.subGenreName ?? '').toLowerCase();
    final tags = (item.tags ?? '').toLowerCase();
    final promoter = (item.promoterName ?? '').toLowerCase();

    if (title.contains(q)) score += 90;
    if (description.contains(q)) score += 30;
    if (segment.contains(q)) score += 28;
    if (genre.contains(q)) score += 24;
    if (subGenre.contains(q)) score += 20;
    if (tags.contains(q)) score += 18;
    if (promoter.contains(q)) score += 14;

    return score;
  }
}