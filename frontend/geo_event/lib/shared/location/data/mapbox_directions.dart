import 'package:dio/dio.dart';
import 'package:geo_event/core/config/app_environment.dart';

class MapboxDirectionsApi {
  final Dio dio;

  const MapboxDirectionsApi(this.dio);

  Future<Map<String, dynamic>> getDrivingRoute({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
  }) async {
    AppEnvironment.validateAll();

    final response = await dio.get<Map<String, dynamic>>(
      'https://api.mapbox.com/directions/v5/mapbox/driving-traffic/'
      '$originLng,$originLat;$destinationLng,$destinationLat',
      queryParameters: {
        'access_token': AppEnvironment.mapboxAccessToken,
        'geometries': 'geojson',
        'overview': 'full',
        'steps': 'true',
      },
    );

    final data = response.data ?? const <String, dynamic>{};
    final routes = data['routes'];
    if (routes is! List || routes.isEmpty) {
      throw Exception('No route found.');
    }

    final first = Map<String, dynamic>.from(routes.first as Map);
    final geometry = Map<String, dynamic>.from(first['geometry'] as Map);

    return {
      'type': 'Feature',
      'properties': {
        'duration': first['duration'],
        'distance': first['distance'],
      },
      'geometry': geometry,
    };
  }
}