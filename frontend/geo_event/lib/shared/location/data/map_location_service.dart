import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geo;

import '../../../core/constants/app_strings.dart';

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
  bool get isFailure => failure != null;
}

class MapLocationService {
  StreamSubscription<geo.Position>? _headingSub;
  StreamSubscription<geo.Position>? _navigationSub;

  static const _highAccuracySettings = geo.LocationSettings(
    accuracy: geo.LocationAccuracy.high,
  );

  static const _navigationSettings = geo.LocationSettings(
    accuracy: geo.LocationAccuracy.bestForNavigation,
    distanceFilter: 10,
  );

  static const _headingSettings = geo.LocationSettings(
    accuracy: geo.LocationAccuracy.bestForNavigation,
    distanceFilter: 0,
  );

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
            accuracy: _highAccuracySettings.accuracy,
            timeLimit: timeLimit,
          ),
        );
        return MapLocationResult.success(position);
      } catch (_) {
        if (lastKnown != null) {
          return MapLocationResult.success(lastKnown);
        }
        return const MapLocationResult.failure(MapLocationFailure.unavailable);
      }
    } catch (error, stackTrace) {
      debugPrint('MapLocationService.getCurrentLocation error: $error');
      debugPrintStack(stackTrace: stackTrace);
      return const MapLocationResult.failure(MapLocationFailure.unknown);
    }
  }

  void startHeadingTracking({
    required ValueChanged<double> onHeading,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    _headingSub?.cancel();

    _headingSub = geo.Geolocator.getPositionStream(
      locationSettings: _headingSettings,
    ).listen(
      (position) {
        final heading = position.heading;
        if (!heading.isNaN) {
          onHeading(heading);
        }
      },
      onError: (error, stackTrace) {
        if (onError != null) onError(error, stackTrace);
      },
    );
  }

  void startNavigationTracking({
    required void Function(geo.Position position) onPosition,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    _navigationSub?.cancel();

    _navigationSub = geo.Geolocator.getPositionStream(
      locationSettings: _navigationSettings,
    ).listen(
      onPosition,
      onError: (error, stackTrace) {
        if (onError != null) onError(error, stackTrace);
      },
    );
  }

  Future<void> stopHeadingTracking() async {
    await _headingSub?.cancel();
    _headingSub = null;
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
    return switch (failure) {
      MapLocationFailure.servicesDisabled =>
        'Location services are disabled. Please enable GPS.',
      MapLocationFailure.permissionDenied =>
        'Location permission was denied.',
      MapLocationFailure.permissionDeniedForever =>
        'Location permission is permanently denied. Enable it in Settings.',
      MapLocationFailure.unavailable =>
        'Unable to determine your position. Try moving outdoors or enabling device location.',
      MapLocationFailure.unknown => AppStrings.genericError,
    };
  }
}