import '../../shared/location/data/mapbox_reverse_geocoding_api.dart';

class LocationHelpers {
  const LocationHelpers._();

  static String formatCoordinates(double lat, double lng) {
    return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
  }

  static Future<String> locationLabel({
    String? placeName,
    double? lat,
    double? lng,
    required MapboxReverseGeocodingApi reverseGeocodingApi,
  }) async {
    if (placeName != null && placeName.trim().isNotEmpty) {
      return placeName.trim();
    }

    if (lat != null && lng != null) {
      try {
        final place = await reverseGeocodingApi.reverseGeocode(
          latitude: lat,
          longitude: lng,
        );

        final subtitle = place?.subtitle?.trim();
        if (subtitle != null && subtitle.isNotEmpty) {
          return subtitle;
        }

        final title = place?.title.trim();
        if (title != null && title.isNotEmpty) {
          return title;
        }
      } catch (_) {}

      return formatCoordinates(lat, lng);
    }

    return 'Unknown location';
  }
}