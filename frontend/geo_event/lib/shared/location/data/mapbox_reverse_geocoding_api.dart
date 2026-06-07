import 'package:dio/dio.dart';

import '../../../../core/config/app_env.dart';
import '../../events/models/create_event_models.dart';

class MapboxReverseGeocodingApi {
  final Dio _dio;

  const MapboxReverseGeocodingApi(this._dio);

  Future<MapboxPlace?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    AppEnv.validate();

    final response = await _dio.get<Map<String, dynamic>>(
      'https://api.mapbox.com/search/geocode/v6/reverse',
      queryParameters: {
        'longitude': longitude,
        'latitude': latitude,
        'access_token': AppEnv.mapboxToken,
        'limit': 1,
        'language': 'en',
      },
    );

    final data = response.data ?? const <String, dynamic>{};
    final features = data['features'];

    if (features is! List || features.isEmpty) return null;

    final raw = features.first;
    if (raw is! Map) return null;

    final feature = Map<String, dynamic>.from(raw);
    final propertiesRaw = feature['properties'];
    final properties = propertiesRaw is Map
        ? Map<String, dynamic>.from(propertiesRaw)
        : const <String, dynamic>{};

    final coordinatesRaw = feature['geometry'];
    final geometry = coordinatesRaw is Map
        ? Map<String, dynamic>.from(coordinatesRaw)
        : const <String, dynamic>{};

    final coords = geometry['coordinates'];
    final resolvedLng = coords is List && coords.length >= 2
        ? (coords[0] as num?)?.toDouble() ?? longitude
        : longitude;
    final resolvedLat = coords is List && coords.length >= 2
        ? (coords[1] as num?)?.toDouble() ?? latitude
        : latitude;

    final title =
        properties['name']?.toString().trim().isNotEmpty == true
            ? properties['name'].toString().trim()
            : feature['name']?.toString().trim().isNotEmpty == true
                ? feature['name'].toString().trim()
                : 'Selected location';

    final subtitle =
        properties['full_address']?.toString().trim().isNotEmpty == true
            ? properties['full_address'].toString().trim()
            : feature['place_formatted']?.toString().trim().isNotEmpty == true
                ? feature['place_formatted'].toString().trim()
                : '$resolvedLat, $resolvedLng';

    return MapboxPlace(
      id: feature['id']?.toString() ?? '$resolvedLat,$resolvedLng',
      title: title,
      subtitle: subtitle,
      latitude: resolvedLat,
      longitude: resolvedLng,
    );
  }
}