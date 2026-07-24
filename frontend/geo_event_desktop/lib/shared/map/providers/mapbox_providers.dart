import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/environment.dart';
import '../data/mapbox_places_service.dart';
import '../data/mapbox_reverse_geocoding_api.dart';

final mapboxAccessTokenProvider = Provider<String>((ref) {
  final token = AppEnvironment.mapboxAccessToken?.trim();

  if (token == null || token.isEmpty) {
    throw StateError(
      'MAPBOX_ACCESS_TOKEN is missing. Pass it using --dart-define=MAPBOX_ACCESS_TOKEN=your_token',
    );
  }

  return token;
});

final mapboxDioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      headers: const {
        'Accept': 'application/json',
      },
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
    ),
  );
});

final mapboxPlacesServiceProvider = Provider<MapboxPlacesService>((ref) {
  final dio = ref.read(mapboxDioProvider);
  final accessToken = ref.read(mapboxAccessTokenProvider);

  return MapboxPlacesService(
    dio: dio,
    accessToken: accessToken,
  );
});

final mapboxReverseGeocodingApiProvider =
    Provider<MapboxReverseGeocodingApi>((ref) {
  final dio = ref.read(mapboxDioProvider);
  return MapboxReverseGeocodingApi(dio);
});