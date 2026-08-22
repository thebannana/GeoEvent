import 'package:flutter/material.dart';

import '../../../core/utils/color_parser.dart';
import 'create_event_models.dart';

enum EventPinPriority {
  high,
  medium,
  low,
}

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

  static const int highThreshold = 90;
  static const int mediumThreshold = 40;

  static const Color fallbackPinColor =
      Color(0xFF7C4DFF);

  factory EventMapPinData.fromEventItem(
    EventItem item,
  ) {
    final score =
        item.recommendationScore.round();

    return EventMapPinData(
      id: item.eventId,
      lat: item.latitude,
      lng: item.longitude,
      title: item.title,
      imageUrl: item.coverImageUrl ??
          (item.imageUrls.isNotEmpty
              ? item.imageUrls.first
              : null),
      categoryColor: resolveCategoryColor(
        item.segmentColor,
      ),
      recommendationScore: score,
      priority: resolvePriority(score),
    );
  }

  static EventPinPriority resolvePriority(
    int score,
  ) {
    if (score >= highThreshold) {
      return EventPinPriority.high;
    }

    if (score >= mediumThreshold) {
      return EventPinPriority.medium;
    }

    return EventPinPriority.low;
  }

  static Color resolveCategoryColor(
    String? rawColor,
  ) {
    final trimmed = rawColor?.trim() ?? '';

    if (trimmed.isEmpty) {
      return fallbackPinColor;
    }

    final parsed = parseHex(trimmed);

    if (parsed.alpha == 0) {
      return fallbackPinColor;
    }

    return parsed;
  }
}