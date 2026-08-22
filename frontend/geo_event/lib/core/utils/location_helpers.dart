import 'dart:math' as math;

import '../../shared/location/data/mapbox_reverse_geocoding_api.dart';

class LocationHelpers {
  const LocationHelpers._();

  static String formatCoordinates(
    double lat,
    double lng,
  ) {
    return '${lat.toStringAsFixed(6)}, '
        '${lng.toStringAsFixed(6)}';
  }

  static Future<String> locationLabel({
    String? placeName,
    double? lat,
    double? lng,
    required MapboxReverseGeocodingApi
        reverseGeocodingApi,
  }) async {
    if (placeName != null &&
        placeName.trim().isNotEmpty) {
      return placeName.trim();
    }

    if (lat != null && lng != null) {
      try {
        final place =
            await reverseGeocodingApi.reverseGeocode(
          latitude: lat,
          longitude: lng,
        );

        final subtitle =
            place?.subtitle?.trim();

        if (subtitle != null &&
            subtitle.isNotEmpty) {
          return subtitle;
        }

        final title =
            place?.title.trim();

        if (title != null &&
            title.isNotEmpty) {
          return title;
        }
      } catch (_) {}

      return formatCoordinates(lat, lng);
    }

    return 'Unknown location';
  }

  static double distanceKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const earthRadiusKm = 6371.0;

    final latitudeDelta =
        _degreesToRadians(lat2 - lat1);

    final longitudeDelta =
        _degreesToRadians(lon2 - lon1);

    final a =
        math.sin(latitudeDelta / 2) *
            math.sin(latitudeDelta / 2) +
        math.cos(
              _degreesToRadians(lat1),
            ) *
            math.cos(
              _degreesToRadians(lat2),
            ) *
            math.sin(longitudeDelta / 2) *
            math.sin(longitudeDelta / 2);

    final safeA = a.clamp(0.0, 1.0);

    final c = 2 *
        math.atan2(
          math.sqrt(safeA),
          math.sqrt(1 - safeA),
        );

    return earthRadiusKm * c;
  }

  static double _degreesToRadians(
    double degrees,
  ) {
    return degrees * math.pi / 180.0;
  }
}