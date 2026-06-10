import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geo_event/shared/location/data/mapbox_directions.dart';

import '../models/event_directions_request.dart';
import 'location_providers.dart';

final pendingDirectionsProvider =
    StateProvider<EventDirectionsRequest?>((ref) => null);

final activeNavigationProvider =
    StateProvider<EventDirectionsRequest?>((ref) => null);

final mapboxDirectionsApiProvider = Provider<MapboxDirectionsApi>((ref) {
  return MapboxDirectionsApi(ref.watch(mapboxDioProvider));
});