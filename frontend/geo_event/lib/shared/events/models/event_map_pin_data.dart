import 'package:flutter/material.dart';

import 'create_event_models.dart';

class EventMapPinData {
  final String id;
  final String title;
  final String? imageUrl;
  final double lng;
  final double lat;
  final Color categoryColor;

  const EventMapPinData({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.lng,
    required this.lat,
    this.categoryColor = const Color(0xFFF8FAFC),
  });

  factory EventMapPinData.fromEventItem(EventItem e) {
    final String? resolvedImageUrl =
        (e.coverImageUrl != null && e.coverImageUrl!.isNotEmpty)
            ? e.coverImageUrl
            : (e.imageUrls.isNotEmpty ? e.imageUrls.first : null);

    return EventMapPinData(
      id: e.eventId.toString(),
      title: e.title,
      imageUrl: resolvedImageUrl,
      lng: e.longitude,
      lat: e.latitude,
      categoryColor: resolveCategoryColor(e),
    );
  }

  static Color resolveCategoryColor(EventItem e) {
    final segment = (e.segmentName ?? '').trim().toLowerCase();
    final genre = (e.genreName ?? '').trim().toLowerCase();
    final subGenre = (e.subGenreName ?? '').trim().toLowerCase();

    final type = '$segment $genre $subGenre';

    if (type.contains('concert') ||
        type.contains('music') ||
        type.contains('live')) {
      return const Color(0xFF8B5CF6);
    }

    if (type.contains('festival')) {
      return const Color(0xFFF59E0B);
    }

    if (type.contains('theatre') ||
        type.contains('theater') ||
        type.contains('art') ||
        type.contains('culture')) {
      return const Color(0xFF4F46E5);
    }

    if (type.contains('sport') ||
        type.contains('football') ||
        type.contains('basketball')) {
      return const Color(0xFF16A34A);
    }

    if (type.contains('nightlife') ||
        type.contains('party') ||
        type.contains('club')) {
      return const Color(0xFFEF4444);
    }

    return const Color(0xFFF8FAFC);
  }
}