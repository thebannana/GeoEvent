import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../../core/config/app_env.dart';

class MapRouteService {
  static const String routeSourceId = 'geoevent-route-source';
  static const String routeLayerId = 'geoevent-route-layer';
  static const Color routeLineColor = Color(0xFF199DFF);
  static const double routeLineWidth = 8.5;

  final Dio _dio;

  MapRouteService({Dio? dio}) : _dio = dio ?? Dio();

  Future<Map<String, dynamic>> fetchRouteGeoJson({
    required double originLng,
    required double originLat,
    required double destinationLng,
    required double destinationLat,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      'https://api.mapbox.com/directions/v5/mapbox/driving-traffic/'
      '$originLng,$originLat;$destinationLng,$destinationLat',
      queryParameters: {
        'access_token': AppEnv.mapboxToken,
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

  Future<void> drawRouteLine({
    required MapboxMap mapboxMap,
    required bool styleLoaded,
    required Map<String, dynamic> routeFeature,
  }) async {
    if (!styleLoaded) return;

    final style = mapboxMap.style;
    final data = jsonEncode({
      'type': 'FeatureCollection',
      'features': [routeFeature],
    });

    try {
      await style.getStyleSourceProperties(routeSourceId);
      await style.setStyleSourceProperty(routeSourceId, 'data', data);
    } catch (_) {
      await style.addSource(
        GeoJsonSource(
          id: routeSourceId,
          data: data,
        ),
      );
    }

    try {
      await style.getStyleLayerProperties(routeLayerId);
    } catch (_) {
      await style.addLayer(
        LineLayer(
          id: routeLayerId,
          sourceId: routeSourceId,
          lineJoin: LineJoin.ROUND,
          lineCap: LineCap.ROUND,
          lineColor: routeLineColor.value,
          lineWidth: routeLineWidth,
        ),
      );
    }

    try {
      await style.setStyleLayerProperty(
        routeLayerId,
        'line-color',
        routeLineColor.value,
      );
      await style.setStyleLayerProperty(
        routeLayerId,
        'line-width',
        routeLineWidth,
      );
      await style.setStyleLayerProperty(routeLayerId, 'line-join', 'round');
      await style.setStyleLayerProperty(routeLayerId, 'line-cap', 'round');
      await style.setStyleLayerProperty(routeLayerId, 'line-opacity', 1.0);
    } catch (_) {}
  }

  Future<void> clearRouteLine(MapboxMap mapboxMap) async {
    try {
      await mapboxMap.style.removeStyleLayer(routeLayerId);
    } catch (_) {}

    try {
      await mapboxMap.style.removeStyleSource(routeSourceId);
    } catch (_) {}
  }
}