import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geo;

enum MapLocationFailure {
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
  unknown,
}

class MapLocationResult {
  final geo.Position? position;
  final MapLocationFailure? failure;

  const MapLocationResult._({
    this.position,
    this.failure,
  });

  const MapLocationResult.success(geo.Position position)
      : this._(position: position);

  const MapLocationResult.failure(MapLocationFailure failure)
      : this._(failure: failure);

  bool get isSuccess => position != null;
}

class MapLocationService {
  StreamSubscription<geo.Position>? _headingSub;
  StreamSubscription<geo.Position>? _navigationSub;

  Future<MapLocationResult> getCurrentLocation({
    Duration timeLimit = const Duration(seconds: 12),
  }) async {
    try {
      final serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const MapLocationResult.failure(
          MapLocationFailure.servicesDisabled,
        );
      }

      var permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
      }

      if (permission == geo.LocationPermission.denied) {
        return const MapLocationResult.failure(
          MapLocationFailure.permissionDenied,
        );
      }

      if (permission == geo.LocationPermission.deniedForever) {
        return const MapLocationResult.failure(
          MapLocationFailure.permissionDeniedForever,
        );
      }

      final lastKnown = await geo.Geolocator.getLastKnownPosition();

      try {
        final position = await geo.Geolocator.getCurrentPosition(
          locationSettings: geo.LocationSettings(
            accuracy: geo.LocationAccuracy.high,
            timeLimit: timeLimit,
          ),
        );
        return MapLocationResult.success(position);
      } catch (_) {
        if (lastKnown != null) {
          return MapLocationResult.success(lastKnown);
        }
        return const MapLocationResult.failure(
          MapLocationFailure.unavailable,
        );
      }
    } catch (error, stackTrace) {
      debugPrint('MapLocationService.getCurrentLocation error: $error');
      debugPrintStack(stackTrace: stackTrace);
      return const MapLocationResult.failure(MapLocationFailure.unknown);
    }
  }

  void startHeadingTracking({
    required ValueChanged<double> onHeading,
  }) {
    _headingSub?.cancel();

    const settings = geo.LocationSettings(
      accuracy: geo.LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );

    _headingSub = geo.Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen((position) {
      final heading = position.heading;
      if (heading.isNaN) return;
      onHeading(heading);
    });
  }

  void startNavigationTracking({
    required void Function(geo.Position position) onPosition,
  }) {
    _navigationSub?.cancel();

    const settings = geo.LocationSettings(
      accuracy: geo.LocationAccuracy.bestForNavigation,
      distanceFilter: 10,
    );

    _navigationSub = geo.Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(onPosition);
  }

  Future<void> stopNavigationTracking() async {
    await _navigationSub?.cancel();
    _navigationSub = null;
  }

  Future<void> dispose() async {
    await _headingSub?.cancel();
    await _navigationSub?.cancel();
    _headingSub = null;
    _navigationSub = null;
  }

  String messageForFailure(MapLocationFailure failure) {
    switch (failure) {
      case MapLocationFailure.servicesDisabled:
        return 'Location services are disabled. Please enable GPS.';
      case MapLocationFailure.permissionDenied:
        return 'Location permission was denied.';
      case MapLocationFailure.permissionDeniedForever:
        return 'Location permission is permanently denied. Enable it in Settings.';
      case MapLocationFailure.unavailable:
        return 'Unable to determine your position. Try moving outdoors or enabling device location.';
      case MapLocationFailure.unknown:
        return 'Location error. Please try again.';
    }
  }
}