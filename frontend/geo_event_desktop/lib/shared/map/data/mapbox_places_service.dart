import 'package:dio/dio.dart';

import '../../../../core/errors/error_mapper.dart';
import '../models/mapbox_place.dart';

class MapboxPlacesService {
  const MapboxPlacesService({
    required this.dio,
    required this.accessToken,
  });

  final Dio dio;
  final String accessToken;

  Future<List<MapboxPlace>> searchLocations(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];

    if (accessToken.isEmpty) {
      throw const FormatException(
        'MAPBOX_ACCESS_TOKEN is missing. Run Flutter with --dart-define=MAPBOX_ACCESS_TOKEN=your_token',
      );
    }

    try {
      final response = await dio.get<dynamic>(
        'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(trimmed)}.json',
        queryParameters: {
          'access_token': accessToken,
          'limit': 5,
          'language': 'en',
          'autocomplete': true,
        },
      );

      final rawData = response.data;
      if (rawData is! Map) return const [];

      final features = Map<String, dynamic>.from(rawData)['features'];
      if (features is! List) return const [];

      final places = features
          .map(_mapFeatureToPlace)
          .whereType<MapboxPlace>()
          .where((e) => e.latitude != 0 || e.longitude != 0)
          .toList()
        ..sort((a, b) => _specificityScore(b).compareTo(_specificityScore(a)));

      return places;
    } on DioException catch (error, stackTrace) {
      throw ErrorMapper.toAppException(error, stackTrace: stackTrace);
    }
  }

  Future<List<MapboxPlace>> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    if (accessToken.isEmpty) {
      throw const FormatException(
        'MAPBOX_ACCESS_TOKEN is missing. Run Flutter with --dart-define=MAPBOX_ACCESS_TOKEN=your_token',
      );
    }

    try {
      final response = await dio.get<dynamic>(
        'https://api.mapbox.com/search/geocode/v6/reverse',
        queryParameters: {
          'longitude': longitude,
          'latitude': latitude,
          'access_token': accessToken,
          'limit': 5,
          'language': 'en',
        },
      );

      final rawData = response.data;
      if (rawData is! Map) return const [];

      final features = Map<String, dynamic>.from(rawData)['features'];
      if (features is! List) return const [];

      return features
          .map(_mapReverseFeatureToPlace)
          .whereType<MapboxPlace>()
          .toList(growable: false);
    } on DioException catch (error, stackTrace) {
      throw ErrorMapper.toAppException(error, stackTrace: stackTrace);
    }
  }

  MapboxPlace? _mapFeatureToPlace(dynamic raw) {
    if (raw is! Map) return null;

    final map = Map<String, dynamic>.from(raw);
    final context = _parseContext(map['context']);
    final properties = _asMap(map['properties']) ?? {};
    final geometry = _asMap(map['geometry']) ?? {};

    var latitude = 0.0;
    var longitude = 0.0;

    final center = map['center'];
    if (center is List && center.length >= 2) {
      longitude = (center[0] as num?)?.toDouble() ?? 0;
      latitude = (center[1] as num?)?.toDouble() ?? 0;
    }

    if (latitude == 0 && longitude == 0) {
      final coords = geometry['coordinates'];
      if (coords is List && coords.length >= 2) {
        longitude = (coords[0] as num?)?.toDouble() ?? 0;
        latitude = (coords[1] as num?)?.toDouble() ?? 0;
      }
    }

    final name = _firstNonEmpty([
      map['text']?.toString(),
      map['name']?.toString(),
      properties['name']?.toString(),
      properties['feature_name']?.toString(),
    ]);

    final fullAddress = _firstNonEmpty([
      map['place_name']?.toString(),
      properties['full_address']?.toString(),
      properties['place_formatted']?.toString(),
    ]);

    final subtitle = _buildSubtitle(
      fullAddress: fullAddress,
      addressNumber: map['address']?.toString().trim(),
      street: _firstNonEmpty([
        map['text']?.toString(),
        _contextText(context, 'street'),
      ]),
      place: _contextText(context, 'place'),
      region: _contextText(context, 'region'),
      country: _contextText(context, 'country'),
    );

    return MapboxPlace(
      id: (map['id'] ?? '').toString(),
      title: name ?? 'Unknown place',
      subtitle: subtitle,
      latitude: latitude,
      longitude: longitude,
    );
  }

  MapboxPlace? _mapReverseFeatureToPlace(dynamic raw) {
  if (raw is! Map) return null;

  final map = Map<String, dynamic>.from(raw);
  final properties = _asMap(map['properties']) ?? {};
  final geometry = _asMap(map['geometry']) ?? {};

  final coords = geometry['coordinates'];

  final double resolvedLongitude =
      coords is List && coords.length >= 2
          ? ((coords[0] as num?)?.toDouble() ?? 0.0)
          : 0.0;

  final double resolvedLatitude =
      coords is List && coords.length >= 2
          ? ((coords[1] as num?)?.toDouble() ?? 0.0)
          : 0.0;

  final title = _firstNonEmpty([
        properties['name']?.toString(),
        map['name']?.toString(),
        map['text']?.toString(),
      ]) ??
      'Selected location';

  final subtitle = _firstNonEmpty([
        properties['full_address']?.toString(),
        map['place_formatted']?.toString(),
        map['place_name']?.toString(),
      ]) ??
      '${resolvedLatitude.toStringAsFixed(5)}, ${resolvedLongitude.toStringAsFixed(5)}';

  return MapboxPlace(
    id: (map['id'] ?? '$resolvedLatitude,$resolvedLongitude').toString(),
    title: title,
    subtitle: subtitle,
    latitude: resolvedLatitude,
    longitude: resolvedLongitude,
  );
}

  String? _buildSubtitle({
    String? fullAddress,
    String? addressNumber,
    String? street,
    String? place,
    String? region,
    String? country,
  }) {
    if (fullAddress != null && fullAddress.isNotEmpty) {
      return fullAddress;
    }

    final parts = <String>[];

    if (addressNumber != null &&
        addressNumber.isNotEmpty &&
        street != null &&
        street.isNotEmpty) {
      parts.add('$addressNumber $street');
    } else if (street != null && street.isNotEmpty) {
      parts.add(street);
    }

    if (place != null && place.isNotEmpty) parts.add(place);
    if (region != null && region.isNotEmpty) parts.add(region);
    if (country != null && country.isNotEmpty) parts.add(country);

    if (parts.isEmpty) return null;
    return _dedupeParts(parts).join(', ');
  }

  int _specificityScore(MapboxPlace place) {
    final subtitle = place.subtitle ?? '';
    var score = 0;
    if (subtitle.isNotEmpty) score += 1;
    if (subtitle.contains(RegExp(r'\d'))) score += 3;
    if (subtitle.contains(',')) score += 2;
    return score;
  }

  List<Map<String, dynamic>> _parseContext(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
  }

  Map<String, dynamic>? _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  List<String> _dedupeParts(List<String> values) {
    final seen = <String>{};
    return values
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty && seen.add(v.toLowerCase()))
        .toList(growable: false);
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  String? _contextText(List<Map<String, dynamic>> context, String prefix) {
    for (final item in context) {
      final id = item['id']?.toString() ?? '';
      if (id.startsWith('$prefix.')) {
        final text = item['text']?.toString().trim();
        if (text != null && text.isNotEmpty) return text;
      }
    }
    return null;
  }
}