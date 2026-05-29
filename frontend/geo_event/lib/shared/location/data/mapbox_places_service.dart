import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_env.dart';
import '../../events/models/create_event_models.dart';

final mapboxAccessTokenProvider = Provider<String>((ref) {
  return AppEnv.mapboxToken;
});

final mapboxDioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: 'https://api.mapbox.com',
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: const {
        'Content-Type': 'application/json',
      },
      validateStatus: (status) => status != null && status >= 200 && status < 300,
    ),
  );
});

final mapboxPlacesServiceProvider = Provider<MapboxPlacesService>((ref) {
  return MapboxPlacesService(
    dio: ref.watch(mapboxDioProvider),
    accessToken: ref.watch(mapboxAccessTokenProvider),
  );
});

class MapboxPlacesService {
  final Dio dio;
  final String accessToken;

  MapboxPlacesService({
    required this.dio,
    required this.accessToken,
  });

  Future<List<MapboxPlace>> searchPlaces(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];

    if (accessToken.isEmpty) {
      throw Exception(
        'MAPBOX_ACCESS_TOKEN is missing. Run Flutter with --dart-define=MAPBOX_ACCESS_TOKEN=your_token',
      );
    }

    final encodedQuery = Uri.encodeComponent(trimmed);

    try {
      final response = await dio.get(
        '/geocoding/v5/mapbox.places/$encodedQuery.json',
        queryParameters: {
          'access_token': accessToken,
          'limit': 5,
          'language': 'en',
        },
      );

      final rawData = response.data;
      if (rawData is! Map) return const [];

      final data = Map<String, dynamic>.from(rawData);
      final rawFeatures = data['features'];
      if (rawFeatures is! List) return const [];

      final places = rawFeatures
          .map(_mapFeatureToPlace)
          .whereType<MapboxPlace>()
          .where((e) => e.latitude != 0 || e.longitude != 0)
          .toList();

      places.sort((a, b) => _specificityScore(b).compareTo(_specificityScore(a)));
      return places;
    } on DioException catch (e) {
      final data = e.response?.data;

      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        throw Exception(
          map['message']?.toString() ??
              map['error']?.toString() ??
              e.message ??
              'Failed to search places.',
        );
      }

      throw Exception(e.message ?? 'Failed to search places.');
    }
  }

  MapboxPlace? _mapFeatureToPlace(dynamic raw) {
    if (raw is! Map) return null;

    final map = Map<String, dynamic>.from(raw);

    final rawContext = map['context'];
    final contextList = rawContext is List
        ? rawContext.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];

    final properties =
        Map<String, dynamic>.from(map['properties'] as Map? ?? const {});
    final geometry =
        Map<String, dynamic>.from(map['geometry'] as Map? ?? const {});

    double latitude = 0;
    double longitude = 0;

    final center = map['center'];
    if (center is List && center.length >= 2) {
      longitude = (center[0] as num?)?.toDouble() ?? 0;
      latitude = (center[1] as num?)?.toDouble() ?? 0;
    }

    final geometryCoords = geometry['coordinates'];
    if ((latitude == 0 && longitude == 0) &&
        geometryCoords is List &&
        geometryCoords.length >= 2) {
      longitude = (geometryCoords[0] as num?)?.toDouble() ?? 0;
      latitude = (geometryCoords[1] as num?)?.toDouble() ?? 0;
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

    final addressNumber = map['address']?.toString().trim();
    final street = _firstNonEmpty([
      map['text']?.toString(),
      _contextText(contextList, 'street'),
    ]);
    final place = _contextText(contextList, 'place');
    final region = _contextText(contextList, 'region');
    final country = _contextText(contextList, 'country');

    final subtitleParts = <String>[];

    if (fullAddress != null && fullAddress.isNotEmpty) {
      subtitleParts.add(fullAddress);
    } else {
      if (addressNumber != null && addressNumber.isNotEmpty && street != null && street.isNotEmpty) {
        subtitleParts.add('$addressNumber $street');
      } else if (street != null && street.isNotEmpty) {
        subtitleParts.add(street);
      }

      if (place != null && place.isNotEmpty) subtitleParts.add(place);
      if (region != null && region.isNotEmpty) subtitleParts.add(region);
      if (country != null && country.isNotEmpty) subtitleParts.add(country);
    }

    final subtitle =
        subtitleParts.isEmpty ? null : _dedupeParts(subtitleParts).join(', ');

    return MapboxPlace(
      id: (map['id'] ?? '').toString(),
      title: name ?? 'Unknown place',
      subtitle: subtitle,
      latitude: latitude,
      longitude: longitude,
    );
  }

  int _specificityScore(MapboxPlace place) {
    final subtitle = place.subtitle ?? '';
    var score = 0;

    if (subtitle.isNotEmpty) score += 1;
    if (subtitle.contains(RegExp(r'\d'))) score += 3;
    if (subtitle.contains(',')) score += 2;
    if (!place.title.toLowerCase().contains('sarajevo')) score += 1;

    return score;
  }

  List<String> _dedupeParts(List<String> values) {
    final seen = <String>{};
    final result = <String>[];

    for (final value in values) {
      final cleaned = value.trim();
      if (cleaned.isEmpty) continue;

      final key = cleaned.toLowerCase();
      if (seen.add(key)) {
        result.add(cleaned);
      }
    }

    return result;
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  String? _contextText(List<Map<String, dynamic>> context, String prefix) {
    for (final item in context) {
      final id = item['id']?.toString() ?? '';
      if (id.startsWith('$prefix.')) {
        final text = item['text']?.toString().trim();
        if (text != null && text.isNotEmpty) {
          return text;
        }
      }
    }
    return null;
  }
}