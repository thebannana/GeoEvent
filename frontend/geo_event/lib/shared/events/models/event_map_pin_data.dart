import 'package:flutter/material.dart';

class EventMapPinData {
  final String id;
  final String title;
  final String? imageUrl;
  final Color categoryColor;
  final double lng;
  final double lat;

  const EventMapPinData({
    required this.id,
    required this.title,
    this.imageUrl,
    this.categoryColor = const Color(0xFF3B82F6),
    required this.lng,
    required this.lat,
  });

  factory EventMapPinData.fromEventItem(dynamic e) {
    final String? coverImageUrl = e.coverImageUrl as String?;
    final List<dynamic>? imageUrls = e.imageUrls as List<dynamic>?;

    final String? resolvedImageUrl =
        (coverImageUrl != null && coverImageUrl.isNotEmpty)
            ? coverImageUrl
            : (imageUrls != null && imageUrls.isNotEmpty)
                ? imageUrls.first as String
                : null;

    return EventMapPinData(
      id: e.eventId.toString(),
      title: e.title as String,
      imageUrl: resolvedImageUrl,
      lng: (e.longitude as num).toDouble(),
      lat: (e.latitude as num).toDouble(),
    );
  }
}