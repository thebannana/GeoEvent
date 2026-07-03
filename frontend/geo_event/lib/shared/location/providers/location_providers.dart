import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geo_event/core/config/app_environment.dart';

import '../../events/models/create_event_models.dart';
import '../data/mapbox_directions_api.dart';
import '../data/mapbox_places_service.dart';
import '../data/mapbox_reverse_geocoding_api.dart';

final mapboxAccessTokenProvider = Provider<String>((ref) {
  return AppEnvironment.mapboxAccessToken;
});

final mapboxDioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: 'https://api.mapbox.com',
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: const {'Content-Type': 'application/json'},
      validateStatus: (status) => status != null && status >= 200 && status < 300,
    ),
  );
});

final mapboxDirectionsApiProvider = Provider<MapboxDirectionsApi>((ref) {
  return MapboxDirectionsApi(ref.watch(mapboxDioProvider));
});

final mapboxReverseGeocodingApiProvider =
    Provider<MapboxReverseGeocodingApi>((ref) {
  return MapboxReverseGeocodingApi(ref.watch(mapboxDioProvider));
});

final mapboxPlacesServiceProvider = Provider<MapboxPlacesService>((ref) {
  return MapboxPlacesService(
    dio: ref.watch(mapboxDioProvider),
    accessToken: ref.watch(mapboxAccessTokenProvider),
  );
});

final reverseGeocodedPlaceProvider =
    FutureProvider.family<MapboxPlace?, ({double latitude, double longitude})>(
  (ref, coords) => ref.watch(mapboxReverseGeocodingApiProvider).reverseGeocode(
        latitude: coords.latitude,
        longitude: coords.longitude,
      ),
);