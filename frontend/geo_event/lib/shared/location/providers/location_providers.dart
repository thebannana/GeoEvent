import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_env.dart';
import '../../events/models/create_event_models.dart';
import '../data/mapbox_places_service.dart';
import '../data/mapbox_reverse_geocoding_api.dart';

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

final reverseGeocodedPlaceProvider =
    FutureProvider.family<MapboxPlace?, ({double latitude, double longitude})>(
  (ref, coords) {
    return ref.watch(mapboxReverseGeocodingApiProvider).reverseGeocode(
          latitude: coords.latitude,
          longitude: coords.longitude,
        );
  },
);

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