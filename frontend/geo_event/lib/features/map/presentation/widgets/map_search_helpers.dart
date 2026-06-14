import 'dart:math' as math;

import '../../../../shared/events/models/create_event_models.dart';

double distanceKm({
  required double lat1,
  required double lon1,
  required double lat2,
  required double lon2,
}) {
  const earthRadiusKm = 6371.0;

  final dLat = _degToRad(lat2 - lat1);
  final dLon = _degToRad(lon2 - lon1);

  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_degToRad(lat1)) *
          math.cos(_degToRad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);

  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusKm * c;
}

double _degToRad(double deg) => deg * (math.pi / 180);

bool isWithinRadius({
  required EventItem item,
  required double userLatitude,
  required double userLongitude,
  required double radiusKm,
}) {
  final distance = distanceKm(
    lat1: userLatitude,
    lon1: userLongitude,
    lat2: item.latitude,
    lon2: item.longitude,
  );

  return distance <= radiusKm;
}

int preferenceScore({
  required EventItem item,
  required Set<int> preferredSegmentIds,
  required Set<int> preferredGenreIds,
  required Set<int> preferredSubGenreIds,
}) {
  var score = 0;

  if (item.segmentId != null && preferredSegmentIds.contains(item.segmentId)) {
    score += 30;
  }
  if (item.genreId != null && preferredGenreIds.contains(item.genreId)) {
    score += 22;
  }
  if (item.subGenreId != null && preferredSubGenreIds.contains(item.subGenreId)) {
    score += 16;
  }
  if (item.isFeatured) {
    score += 6;
  }

  return score;
}

List<EventItem> rankByPreferences({
  required List<EventItem> items,
  required Set<int> preferredSegmentIds,
  required Set<int> preferredGenreIds,
  required Set<int> preferredSubGenreIds,
}) {
  final ranked = [...items];
  ranked.sort(
    (a, b) => preferenceScore(
      item: b,
      preferredSegmentIds: preferredSegmentIds,
      preferredGenreIds: preferredGenreIds,
      preferredSubGenreIds: preferredSubGenreIds,
    ).compareTo(
      preferenceScore(
        item: a,
        preferredSegmentIds: preferredSegmentIds,
        preferredGenreIds: preferredGenreIds,
        preferredSubGenreIds: preferredSubGenreIds,
      ),
    ),
  );
  return ranked;
}

List<EventItem> rankSearchResults({
  required List<EventItem> items,
  required String query,
  required bool showGlobalEvents,
  required double selectedRadiusKm,
  required double userLatitude,
  required double userLongitude,
  required Set<int> preferredSegmentIds,
  required Set<int> preferredGenreIds,
  required Set<int> preferredSubGenreIds,
}) {
  final q = query.toLowerCase();
  final ranked = [...items];

  int score(EventItem item) {
    var total = 0;

    final title = item.title.toLowerCase();
    final segment = (item.segmentName ?? '').toLowerCase();
    final genre = (item.genreName ?? '').toLowerCase();
    final subGenre = (item.subGenreName ?? '').toLowerCase();
    final tags = (item.tags ?? '').toLowerCase();

    if (title.contains(q)) total += 80;
    if (segment.contains(q)) total += 30;
    if (genre.contains(q)) total += 25;
    if (subGenre.contains(q)) total += 20;
    if (tags.contains(q)) total += 15;

    total += preferenceScore(
      item: item,
      preferredSegmentIds: preferredSegmentIds,
      preferredGenreIds: preferredGenreIds,
      preferredSubGenreIds: preferredSubGenreIds,
    );

    total += (item.likesCount / 20).round();
    total += (item.viewCount / 200).round();

    if (!showGlobalEvents) {
      final distance = distanceKm(
        lat1: userLatitude,
        lon1: userLongitude,
        lat2: item.latitude,
        lon2: item.longitude,
      );

      total += distance <= selectedRadiusKm ? 20 : -20;
    }

    return total;
  }

  ranked.sort((a, b) => score(b).compareTo(score(a)));
  return ranked;
}