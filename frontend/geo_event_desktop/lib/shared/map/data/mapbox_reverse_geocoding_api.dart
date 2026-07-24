import 'package:dio/dio.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../core/config/environment.dart';
import '../models/mapbox_place.dart';

class MapboxReverseGeocodingApi {
  const MapboxReverseGeocodingApi(this._dio);

  final Dio _dio;

  Future<MapboxPlace?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    AppEnvironment.validateMaps();

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.mapbox.com/search/geocode/v6/reverse',
        queryParameters: {
          'longitude': longitude,
          'latitude': latitude,
          'access_token': AppEnvironment.mapboxAccessToken,
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
      final properties = _asMap(feature['properties']) ?? {};
      final geometry = _asMap(feature['geometry']) ?? {};

      final coords = geometry['coordinates'];
      final resolvedLng = coords is List && coords.length >= 2
          ? (coords[0] as num?)?.toDouble() ?? longitude
          : longitude;
      final resolvedLat = coords is List && coords.length >= 2
          ? (coords[1] as num?)?.toDouble() ?? latitude
          : latitude;

      final title = _firstNonEmpty([
            properties['name']?.toString(),
            feature['name']?.toString(),
          ]) ??
          'Selected location';

      final subtitle = _firstNonEmpty([
            properties['full_address']?.toString(),
            feature['place_formatted']?.toString(),
          ]) ??
          '$resolvedLat, $resolvedLng';

      return MapboxPlace(
        id: feature['id']?.toString() ?? '$resolvedLat,$resolvedLng',
        title: title,
        subtitle: subtitle,
        latitude: resolvedLat,
        longitude: resolvedLng,
      );
    } catch (error, stackTrace) {
      throw ErrorMapper.toAppException(error, stackTrace: stackTrace);
    }
  }

  Map<String, dynamic>? _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}