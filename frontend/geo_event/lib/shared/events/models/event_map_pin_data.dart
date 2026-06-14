import 'package:flutter/material.dart';

import '../../../core/utils/color_utils.dart';
import 'create_event_models.dart';

enum EventPinPriority {
  high,
  medium,
  low,
}

class EventMapPinData {
  final String id;
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

  factory EventMapPinData.fromEventItem(
    EventItem item, {
    int recommendationScore = 0,
  }) {
    final priority = recommendationScore >= 60
        ? EventPinPriority.high
        : recommendationScore >= 35
            ? EventPinPriority.medium
            : EventPinPriority.low;

    return EventMapPinData(
      id: item.eventId.toString(),
      lat: item.latitude,
      lng: item.longitude,
      title: item.title,
      imageUrl: item.coverImageUrl ??
          (item.imageUrls.isNotEmpty ? item.imageUrls.first : null),
      categoryColor: parseHexColor(item.segmentColor),
      recommendationScore: recommendationScore,
      priority: priority,
    );
  }
}