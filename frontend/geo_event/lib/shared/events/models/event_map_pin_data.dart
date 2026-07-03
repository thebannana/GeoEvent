import 'package:flutter/material.dart';

import '../../../core/utils/color_parser.dart';
import 'create_event_models.dart';

enum EventPinPriority { high, medium, low }

class EventMapPinData {
  final int id;
  final double lat;
  final double lng;
  final String title;
  final String? imageUrl;
  final Color categoryColor;
  final int recommendationScore;
  final EventPinPriority priority;

  const EventMapPinData({
    required this.id,
    required this.lat,
    required this.lng,
    required this.title,
    required this.imageUrl,
    required this.categoryColor,
    required this.recommendationScore,
    required this.priority,
  });

  static const int _highThreshold = 60;
  static const int _mediumThreshold = 35;
  static const Color _fallbackPinColor = Color(0xFF7C4DFF);

  factory EventMapPinData.fromEventItem(
    EventItem item, {
    int recommendationScore = 0,
  }) {
    return EventMapPinData(
      id: item.eventId,
      lat: item.latitude,
      lng: item.longitude,
      title: item.title,
      imageUrl: item.coverImageUrl ??
          (item.imageUrls.isNotEmpty ? item.imageUrls.first : null),
      categoryColor: _resolveCategoryColor(item.segmentColor),
      recommendationScore: recommendationScore,
      priority: _resolvePriority(recommendationScore),
    );
  }

  static EventPinPriority _resolvePriority(int score) {
    if (score >= _highThreshold) return EventPinPriority.high;
    if (score >= _mediumThreshold) return EventPinPriority.medium;
    return EventPinPriority.low;
  }

  static Color _resolveCategoryColor(String? rawColor) {
    final trimmed = rawColor?.trim() ?? '';
    if (trimmed.isEmpty) return _fallbackPinColor;

    final parsed = parseHex(trimmed);
    if (parsed.alpha == 0) return _fallbackPinColor;

    return parsed;
  }
}