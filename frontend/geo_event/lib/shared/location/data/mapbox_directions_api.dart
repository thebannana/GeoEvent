import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geo_event/core/config/app_environment.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../../core/errors/error_mapper.dart';

class MapboxDirectionsApi {
  const MapboxDirectionsApi(this._dio);

  final Dio _dio;

  static const _baseUrl =
      'https://api.mapbox.com/directions/v5/mapbox/driving-traffic';

  Future<Map<String, dynamic>> getDrivingRoute({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
  }) async {
    AppEnvironment.validateAll();

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/$originLng,$originLat;$destinationLng,$destinationLat',
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
        throw const FormatException('No route found.');
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
    } catch (error, stackTrace) {
      throw ErrorMapper.toAppException(error, stackTrace: stackTrace);
    }
  }
}

class MapRouteDrawer {
  static const String _sourceId = 'geoevent-route-source';
  static const String _layerId = 'geoevent-route-layer';
  static const Color _routeColor = Color(0xFF199DFF);
  static const double _routeWidth = 8.5;

  static Future<void> draw({
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
      await style.getStyleSourceProperties(_sourceId);
      await style.setStyleSourceProperty(_sourceId, 'data', data);
    } catch (_) {
      await style.addSource(GeoJsonSource(id: _sourceId, data: data));
    }

    try {
      await style.getStyleLayerProperties(_layerId);
    } catch (_) {
      await style.addLayer(
        LineLayer(
          id: _layerId,
          sourceId: _sourceId,
          lineJoin: LineJoin.ROUND,
          lineCap: LineCap.ROUND,
          lineColor: _routeColor.value,
          lineWidth: _routeWidth,
        ),
      );
    }

    try {
      await style.setStyleLayerProperty(_layerId, 'line-color', _routeColor.value);
      await style.setStyleLayerProperty(_layerId, 'line-width', _routeWidth);
      await style.setStyleLayerProperty(_layerId, 'line-join', 'round');
      await style.setStyleLayerProperty(_layerId, 'line-cap', 'round');
      await style.setStyleLayerProperty(_layerId, 'line-opacity', 1.0);
    } catch (_) {}
  }

  static Future<void> clear(MapboxMap mapboxMap) async {
    try {
      await mapboxMap.style.removeStyleLayer(_layerId);
    } catch (_) {}
    try {
      await mapboxMap.style.removeStyleSource(_sourceId);
    } catch (_) {}
  }
}