import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../../core/config/app_environment.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/feedback/app_loading_indicator.dart';
import '../../../../shared/events/models/event_map_pin_data.dart';
import '../../../../shared/events/providers/event_providers.dart';
import '../../../../shared/events/providers/event_refresh_providers.dart';
import '../../../../shared/location/data/map_location_service.dart';
import '../../../../shared/location/data/map_pin_annotations_service.dart';
import '../../../../shared/location/data/mapbox_directions_api.dart';
import '../../../../shared/location/models/event_directions_request.dart';
import '../../../../shared/location/models/map_filter_selection.dart';
import '../../../../shared/location/providers/directions_providers.dart';
import '../../../../shared/location/providers/location_providers.dart';
import '../../../event/presentation/screens/event_detail_screen.dart';
import '../../application/map_settings_controller.dart';
import '../widgets/active_navigation_card.dart';
import '../widgets/directions_action_card.dart';

extension PuckPositionX on StyleManager {
  Future<Position?> getPuckPositionSafe() async {
    try {
      final Layer? layer = Platform.isAndroid
          ? await getLayer('mapbox-location-indicator-layer')
          : await getLayer('puck');

      if (layer is! LocationIndicatorLayer) {
        return null;
      }

      final location = layer.location;

      if (location == null || location.length < 2) {
        return null;
      }

      return Position(
        (location[1] ?? 0).toDouble(),
        (location[0] ?? 0).toDouble(),
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Unable to read puck position.',
        tag: 'MapHomeScreen',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}

class MapHomeScreen extends ConsumerStatefulWidget {
  final ValueChanged<MapboxMap>? onMapReady;
  final ValueChanged<double>? onBearingChanged;
  final ValueChanged<int>? onEventSelected;
  final MapFilterSelection filterSelection;
  final VoidCallback? onCloseSearchOverlay;
  final ValueChanged<bool>? onNavigationUiVisibilityChanged;

  const MapHomeScreen({
    super.key,
    this.onMapReady,
    this.onBearingChanged,
    this.onEventSelected,
    this.onCloseSearchOverlay,
    this.onNavigationUiVisibilityChanged,
    this.filterSelection = const MapFilterSelection(),
  });

  @override
  ConsumerState<MapHomeScreen> createState() => MapHomeScreenState();
}

class MapHomeScreenState extends ConsumerState<MapHomeScreen>
    with WidgetsBindingObserver {
  static const double baseZoom = 13.0;
  static const double cityZoom = 15.5;
  static const double cityPitch = 60.0;
  static const double defaultLng = 18.4131;
  static const double defaultLat = 43.8563;

  final MapLocationService locationService = MapLocationService();
  final MapPinAnnotationService pinService = MapPinAnnotationService();

  ProviderSubscription<MapSettingsState>? settingsSubscription;
  ProviderSubscription<EventDirectionsRequest?>?
      pendingDirectionsSubscription;
  ProviderSubscription<int>? eventRefreshSubscription;

  Timer? pinsRefreshTimer;
  MapboxMap? mapboxMap;

  List<EventMapPinData> events = <EventMapPinData>[];

  bool styleLoaded = false;
  bool captureReady = false;
  bool isLoadingMapPins = false;
  bool isSyncingPins = false;
  bool isReloadingPins = false;
  bool handlingPendingDirections = false;
  bool hasHandledInitialPendingDirections = false;
  bool isFetchingRoute = false;
  bool isNavigationUiOpen = false;
  int _mapRequestVersion = 0;

  geo.Position? lastReroutePosition;
  bool isRerouting = false;

  EventDirectionsRequest? activeDirectionsRequest;

  double? currentLatitude;
  double? currentLongitude;
  double _currentZoom = baseZoom;

  MapboxDirectionsApi get _directionsApi =>
      ref.read(mapboxDirectionsApiProvider);

  EventDirectionsRequest? get activeNavigationRequest =>
      ref.read(activeNavigationProvider);

  set activeNavigationRequest(EventDirectionsRequest? value) {
    ref.read(activeNavigationProvider.notifier).state = value;
  }

  bool get _hasMap => mapboxMap != null;
  bool get _canSyncPins => _hasMap && styleLoaded && captureReady;
  bool get _isReadyForPendingDirections => mounted && _canSyncPins;
  bool get _showMapLoadingOverlay => !styleLoaded || isLoadingMapPins;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    AppEnvironment.validateAll();
    MapboxOptions.setAccessToken(
      AppEnvironment.mapboxAccessToken,
    );

    _startHeadingTracking();
    _listenToMapSettings();
    _listenToPendingDirections();
    _listenToEventRefresh();
    _scheduleInitialLoad();
    _startPinsAutoRefresh();
  }
  
@override
void didUpdateWidget(
  covariant MapHomeScreen oldWidget,
) {
  super.didUpdateWidget(oldWidget);

  if (oldWidget.filterSelection !=
      widget.filterSelection) {
    unawaited(
      reloadMapPins(
        forceResync: true,
        silent: false,
      ),
    );
  }
}

@override
void didChangeAppLifecycleState(
  AppLifecycleState state,
) {
  if (state == AppLifecycleState.resumed &&
      mounted) {
    unawaited(
      reloadMapPins(
        silent: true,
        forceResync: true,
      ),
    );
  }
}

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    pinsRefreshTimer?.cancel();
    pinsRefreshTimer = null;

    settingsSubscription?.close();
    pendingDirectionsSubscription?.close();
    eventRefreshSubscription?.close();

    settingsSubscription = null;
    pendingDirectionsSubscription = null;
    eventRefreshSubscription = null;

    unawaited(pinService.dispose());
    unawaited(locationService.dispose());

    super.dispose();
  }

void _startPinsAutoRefresh() {
  pinsRefreshTimer?.cancel();
  pinsRefreshTimer = Timer.periodic(
    const Duration(minutes: 1),
    (_) => reloadMapPins(silent: true),
  );
}

  void _startHeadingTracking() {
    locationService.startHeadingTracking(
      onHeading: (heading) {
        if (mounted) {
          widget.onBearingChanged?.call(heading);
        }
      },
    );
  }

  void _listenToMapSettings() {
    settingsSubscription?.close();

    settingsSubscription = ref.listenManual<MapSettingsState>(
      mapSettingsControllerProvider,
      (previous, next) async {
        if (!mounted || previous == null) {
          return;
        }

        if (previous.map3D != next.map3D) {
          await applyStandardMapConfiguration(next);
          await animateCameraFor3D(next.map3D);
        }

        if (previous.dayNightCycle != next.dayNightCycle ||
            previous.mapPins != next.mapPins) {
          await applyStandardMapConfiguration(next);
        }

        if (previous.eventPins != next.eventPins) {
          await applyEventPinsVisibility(next.eventPins);
        }
      },
    );
  }

  void _listenToPendingDirections() {
    pendingDirectionsSubscription?.close();

    pendingDirectionsSubscription =
        ref.listenManual<EventDirectionsRequest?>(
      pendingDirectionsProvider,
      (_, next) async {
        if (!mounted || next == null || handlingPendingDirections) {
          return;
        }

        await tryHandlePendingDirections(next);
      },
    );
  }

void _listenToEventRefresh() {
  eventRefreshSubscription?.close();
  eventRefreshSubscription = ref.listenManual<int>(
    eventMapRefreshProvider,
    (previous, next) async {
      if (previous == next) return;
      await reloadMapPins(forceResync: true);
    },
  );
}

void _scheduleInitialLoad() {
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (!mounted) return;
    setState(() => captureReady = true);
    await reloadMapPins();
    await consumeInitialPendingDirectionsIfNeeded();
  });
}

  void _setLoadingPins(bool value) {
    if (!mounted) {
      return;
    }

    setState(() {
      isLoadingMapPins = value;
    });
  }

  void _setNavigationUiOpen(bool value) {
    if (!mounted) {
      return;
    }

    setState(() {
      isNavigationUiOpen = value;
    });
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

Future<void> onMapCreated(
  MapboxMap createdMap,
) async {
  mapboxMap = createdMap;
  widget.onMapReady?.call(createdMap);

  await hideBuiltInCompass();
  await enableUserLocation();

  await pinService.prepare(
    mapboxMap: createdMap,
    onEventTap: handleEventTap,
  );

  await consumeInitialPendingDirectionsIfNeeded();
}

  Future<void> onStyleLoaded(
  StyleLoadedEventData data,
) async {
  final map = mapboxMap;

  if (map == null) {
    return;
  }

  await hideBuiltInCompass();

  await pinService.prepare(
    mapboxMap: map,
    onEventTap: handleEventTap,
  );

  if (!mounted) {
    return;
  }

  setState(() {
    styleLoaded = true;
    captureReady = true;
  });

  final settings = ref.read(
    mapSettingsControllerProvider,
  );

  await applyStandardMapConfiguration(
    settings,
  );

  await applyEventPinsVisibility(
    settings.eventPins,
  );

  await reloadMapPins(
    silent: false,
    forceResync: true,
  );

  await consumeInitialPendingDirectionsIfNeeded();
}

  String get baseStyleUri => MapboxStyles.STANDARD;

  String resolveLightPreset() {
    final hour = DateTime.now().toUtc().hour;

    if (hour >= 5 && hour < 8) return 'dawn';
    if (hour >= 8 && hour < 18) return 'day';
    if (hour >= 18 && hour < 20) return 'dusk';

    return 'night';
  }

  Future<void> hideBuiltInCompass() async {
    final map = mapboxMap;

    if (map == null) {
      return;
    }

    await map.compass.updateSettings(
      CompassSettings(
        enabled: false,
        opacity: 0.0,
        position: OrnamentPosition.BOTTOM_LEFT,
        marginLeft: -1000,
        marginBottom: -1000,
        marginRight: 0,
        marginTop: 0,
        fadeWhenFacingNorth: false,
      ),
    );
  }

  Future<void> enableUserLocation() async {
    final map = mapboxMap;

    if (map == null) {
      return;
    }

    await map.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        puckBearingEnabled: true,
        puckBearing: PuckBearing.HEADING,
      ),
    );
  }

  Future<geo.Position?> getCurrentDeviceLocation() async {
    final result = await locationService.getCurrentLocation();

    if (result.position != null) {
      currentLatitude = result.position!.latitude;
      currentLongitude = result.position!.longitude;
      return result.position!;
    }

    if (result.failure != null && mounted) {
      _showMessage(
        locationService.messageForFailure(result.failure!),
      );
    }

    return null;
  }

  Future<Position?> getUserPosition() async {
    final map = mapboxMap;

    if (map == null) {
      return null;
    }

    final position = await map.style.getPuckPositionSafe();

    if (position != null) {
      currentLatitude = position.lat.toDouble();
      currentLongitude = position.lng.toDouble();
    }

    return position;
  }

  Future<void> applyStandardMapConfiguration(
    MapSettingsState settings,
  ) async {
    final map = mapboxMap;

    if (map == null || !styleLoaded) {
      return;
    }

    final style = map.style;

    await _runMapTask(
      () => style.setStyleImportConfigProperty(
        'basemap',
        'lightPreset',
        settings.dayNightCycle
            ? resolveLightPreset()
            : 'day',
      ),
      debugLabel: 'Failed to apply map light preset.',
    );

    await _runMapTask(
      () => style.setStyleImportConfigProperty(
        'basemap',
        'showPointOfInterestLabels',
        true,
      ),
      debugLabel: 'Failed to apply POI label visibility.',
    );

    await _runMapTask(
      () => style.setStyleImportConfigProperty(
        'basemap',
        'showTransitLabels',
        true,
      ),
      debugLabel: 'Failed to apply transit label visibility.',
    );

    await _runMapTask(
      () => style.setStyleImportConfigProperty(
        'basemap',
        'showPlaceLabels',
        true,
      ),
      debugLabel: 'Failed to apply place label visibility.',
    );

    await _runMapTask(
      () => style.setStyleImportConfigProperty(
        'basemap',
        'showRoadLabels',
        true,
      ),
      debugLabel: 'Failed to apply road label visibility.',
    );

    await _runMapTask(
      () => style.setStyleImportConfigProperty(
        'basemap',
        'show3dObjects',
        settings.map3D,
      ),
      debugLabel: 'Failed to apply 3D object visibility.',
    );
  }

  Future<void> animateCameraFor3D(bool enabled) async {
    final map = mapboxMap;

    if (map == null) {
      return;
    }

    await map.easeTo(
      CameraOptions(
        zoom: enabled ? cityZoom : baseZoom,
        pitch: enabled ? cityPitch : 0.0,
      ),
      MapAnimationOptions(
        duration: 550,
        startDelay: 0,
      ),
    );
  }

  Future<void> focusOnEventLocation({
    required double latitude,
    required double longitude,
  }) async {
    final settings = ref.read(mapSettingsControllerProvider);

    await _animateToPoint(
      latitude: latitude,
      longitude: longitude,
      zoom: settings.map3D ? cityZoom : 15.8,
      pitch: settings.map3D ? cityPitch : 0.0,
      padding: MbxEdgeInsets(
        top: 120,
        left: 40,
        right: 40,
        bottom: 260,
      ),
    );
  }

  Future<void> centerOnUserPuck() async {
    final map = mapboxMap;

    if (map == null) {
      return;
    }

    final puck = await getUserPosition();

    if (puck != null) {
      await map.easeTo(
        CameraOptions(
          center: Point(
            coordinates: Position(
              puck.lng.toDouble(),
              puck.lat.toDouble(),
            ),
          ),
          zoom: 16.0,
          pitch: 0.0,
          bearing: 0.0,
        ),
        MapAnimationOptions(
          duration: 700,
          startDelay: 0,
        ),
      );
      return;
    }

    final gps = await getCurrentDeviceLocation();

    if (gps == null) {
      return;
    }

    await map.easeTo(
      CameraOptions(
        center: Point(
          coordinates: Position(
            gps.longitude,
            gps.latitude,
          ),
        ),
        zoom: 16.0,
        pitch: 0.0,
        bearing: 0.0,
      ),
      MapAnimationOptions(
        duration: 700,
        startDelay: 0,
      ),
    );
  }

  List<EventMapPinData> visiblePinsForZoom({
  required List<EventMapPinData> pins,
  required double zoom,
  required bool usePreferences,
}) {
  if (pins.isEmpty) {
    return const <EventMapPinData>[];
  }

  if (zoom < 12.0) {
    return pins;
  }

  final maxCount = zoom >= 13.5 ? 40 : 20;

  return pins.take(maxCount).toList();
}

  Future<List<EventMapPinData>> fetchMapPins() async {
  try {
    final filters = widget.filterSelection;

    AppLogger.info(
      'Fetching map pins with filter: '
      'segment=${filters.segmentId}, '
      'genre=${filters.genreId}, '
      'subGenre=${filters.subGenreId}, '
      'todayOnly=${filters.todayOnly}, '
      'freeOnly=${filters.freeOnly}, '
      'minPrice=${filters.minPrice}, '
      'maxPrice=${filters.maxPrice}, '
      'radius=${filters.radiusKm}, '
      'global=${filters.showGlobalEvents}, '
      'usePreferences=${filters.usePreferences}',
      tag: 'MapHomeScreen',
    );

    if (!mounted) {
      return <EventMapPinData>[];
    }

    final api = ref.read(eventsApiProvider);

    final devicePosition =
        await getCurrentDeviceLocation();

    if (!mounted) {
      return <EventMapPinData>[];
    }

    final userLat = devicePosition?.latitude ??
        currentLatitude ??
        defaultLat;

    final userLng = devicePosition?.longitude ??
        currentLongitude ??
        defaultLng;

    final items = filters.showGlobalEvents
        ? await api.getGlobalEvents(
            pageSize: 100,
            segmentId: filters.segmentId,
            genreId: filters.genreId,
            subGenreId: filters.subGenreId,
            minPrice: filters.minPrice,
            maxPrice: filters.maxPrice,
            freeOnly: filters.freeOnly,
            todayOnly: filters.todayOnly,
            usePreferences:
                filters.usePreferences,
          )
        : await api.getNearbyEvents(
            latitude: userLat,
            longitude: userLng,
            radiusKm: filters.radiusKm,
            limit: 100,
            segmentId: filters.segmentId,
            genreId: filters.genreId,
            subGenreId: filters.subGenreId,
            minPrice: filters.minPrice,
            maxPrice: filters.maxPrice,
            freeOnly: filters.freeOnly,
            todayOnly: filters.todayOnly,
            usePreferences:
                filters.usePreferences,
          );

    if (!mounted) {
      return <EventMapPinData>[];
    }

    AppLogger.info(
      'Received ${items.length} backend-ranked map events.',
      tag: 'MapHomeScreen',
    );

    for (final item in items) {
      AppLogger.info(
        'Map event ${item.eventId}: '
        '${item.title}, '
        'backendScore=${item.recommendationScore}',
        tag: 'MapHomeScreen',
      );
    }

    return items
        .map(EventMapPinData.fromEventItem)
        .toList();
  } catch (error, stackTrace) {
    if (mounted) {
      AppLogger.error(
        'Failed to fetch map pins.',
        tag: 'MapHomeScreen',
        error: error,
        stackTrace: stackTrace,
      );
    }

    return <EventMapPinData>[];
  }
}

Future<void> reloadMapPins({
  bool silent = false,
  bool forceResync = false,
}) async {
  if (!mounted ||
      !styleLoaded ||
      mapboxMap == null) {
    return;
  }

  final requestVersion =
      ++_mapRequestVersion;

  if (!silent) {
    _setLoadingPins(true);
  }

  try {
    final pins = await fetchMapPins();

    if (!mounted ||
        requestVersion != _mapRequestVersion) {
      return;
    }

    AppLogger.info(
      'Map pin request $requestVersion returned '
      '${pins.length} pins: '
      '${pins.map(
        (event) =>
            '${event.id}:${event.recommendationScore}',
      ).join(', ')}',
      tag: 'MapHomeScreen',
    );

    final oldSignature = events
        .map(
          (event) =>
              '${event.id}-'
              '${event.lat}-'
              '${event.lng}-'
              '${event.imageUrl}-'
              '${event.recommendationScore}-'
              '${event.categoryColor.value}',
        )
        .join('|');

    final newSignature = pins
        .map(
          (event) =>
              '${event.id}-'
              '${event.lat}-'
              '${event.lng}-'
              '${event.imageUrl}-'
              '${event.recommendationScore}-'
              '${event.categoryColor.value}',
        )
        .join('|');

    if (oldSignature == newSignature &&
        !forceResync) {
      return;
    }

    setState(() {
      events = pins;
      isLoadingMapPins = false;
    });

    if (pins.isEmpty) {
      await pinService.clear();
      return;
    }

    await WidgetsBinding.instance.endOfFrame;

    if (!mounted ||
        requestVersion != _mapRequestVersion) {
      return;
    }

    await syncEventPins();
  } catch (error, stackTrace) {
    if (!mounted ||
        requestVersion != _mapRequestVersion) {
      return;
    }

    AppLogger.error(
      'Failed to reload map pins.',
      tag: 'MapHomeScreen',
      error: error,
      stackTrace: stackTrace,
    );

    await pinService.clear();
  } finally {
    if (requestVersion == _mapRequestVersion &&
        mounted &&
        !silent) {
      _setLoadingPins(false);
    }
  }
}

  Future<void> syncEventPins({
  bool forceResync = false,
}) async {
  if (!mounted || !_canSyncPins) {
    return;
  }

  if (isSyncingPins) {
    return;
  }

  final settings = ref.read(
    mapSettingsControllerProvider,
  );

  if (!settings.eventPins) {
    await pinService.clear();
    return;
  }

  final visiblePins = visiblePinsForZoom(
    pins: events,
    zoom: _currentZoom,
    usePreferences:
        widget.filterSelection.usePreferences,
  );

  if (visiblePins.isEmpty) {
    await pinService.clear();

    AppLogger.info(
      'No map pins match the active filter.',
      tag: 'MapHomeScreen',
    );

    return;
  }

  isSyncingPins = true;

  try {
    await pinService.syncPins(
      events: visiblePins,
    );
  } catch (error, stackTrace) {
    AppLogger.error(
      'Failed to synchronize map pins.',
      tag: 'MapHomeScreen',
      error: error,
      stackTrace: stackTrace,
    );

    await pinService.clear();
  } finally {
    isSyncingPins = false;
  }
}

Future<void> tryAddEventPins() async {
  await syncEventPins();
}

Future<void> applyEventPinsVisibility(
  bool visible,
) async {
  await pinService.clear();

  if (visible) {
    await tryAddEventPins();
  }

  if (mounted) {
    setState(() {});
  }
}

  Future<void> tryHandlePendingDirections(
    EventDirectionsRequest request,
  ) async {
    if (activeNavigationRequest?.eventId == request.eventId) {
      if (mounted) {
        ref.read(pendingDirectionsProvider.notifier).state = null;

        setState(() {
          isNavigationUiOpen = true;
          activeDirectionsRequest = null;
        });
      }

      notifyNavigationIconVisibility();
      return;
    }

    if (!_isReadyForPendingDirections) {
      await Future<void>.delayed(
        const Duration(milliseconds: 250),
      );
    }

    if (!_isReadyForPendingDirections || !mounted) {
      return;
    }

    handlingPendingDirections = true;

    try {
      await focusOnEventLocation(
        latitude: request.latitude,
        longitude: request.longitude,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        activeDirectionsRequest = request;
        isNavigationUiOpen = false;
      });

      ref.read(pendingDirectionsProvider.notifier).state = null;
      hasHandledInitialPendingDirections = true;
      notifyNavigationIconVisibility();
    } finally {
      handlingPendingDirections = false;
    }
  }

  Future<void> consumeInitialPendingDirectionsIfNeeded() async {
    if (!mounted || hasHandledInitialPendingDirections) {
      return;
    }

    final request = ref.read(pendingDirectionsProvider);

    if (request == null) {
      hasHandledInitialPendingDirections = true;
      return;
    }

    await tryHandlePendingDirections(request);
  }

  Future<Map<String, dynamic>> _fetchRouteFeature({
    required double originLng,
    required double originLat,
    required double destinationLng,
    required double destinationLat,
  }) {
    return _directionsApi.getDrivingRoute(
      originLng: originLng,
      originLat: originLat,
      destinationLng: destinationLng,
      destinationLat: destinationLat,
    );
  }

  void startNavigationTracking(
    EventDirectionsRequest request,
  ) {
    lastReroutePosition = null;
    isRerouting = false;

    locationService.startNavigationTracking(
      onPosition: (position) async {
        if (!mounted) {
          return;
        }

        currentLatitude = position.latitude;
        currentLongitude = position.longitude;

        if (isRerouting) {
          return;
        }

        final last = lastReroutePosition;
        final movedEnough = last == null ||
            geo.Geolocator.distanceBetween(
                  last.latitude,
                  last.longitude,
                  position.latitude,
                  position.longitude,
                ) >=
                25;

        if (!movedEnough || mapboxMap == null) {
          return;
        }

        isRerouting = true;
        lastReroutePosition = position;

        try {
          final routeFeature = await _fetchRouteFeature(
            originLng: position.longitude,
            originLat: position.latitude,
            destinationLng: request.longitude,
            destinationLat: request.latitude,
          );

          if (!mounted || mapboxMap == null) {
            return;
          }

          await MapRouteDrawer.draw(
            mapboxMap: mapboxMap!,
            styleLoaded: styleLoaded,
            routeFeature: routeFeature,
          );
        } catch (error, stackTrace) {
          _logMapWarning(
            'Failed to reroute active navigation.',
            error: error,
            stackTrace: stackTrace,
          );
        } finally {
          isRerouting = false;
        }
      },
    );
  }

  Future<void> startDirections(
    EventDirectionsRequest request,
  ) async {
    final origin = await getCurrentDeviceLocation();
    final map = mapboxMap;

    if (origin == null || map == null) {
      return;
    }

    await locationService.stopNavigationTracking();

    lastReroutePosition = origin;
    isRerouting = false;

    if (mounted) {
      setState(() {
        isFetchingRoute = true;
        activeNavigationRequest = request;
        activeDirectionsRequest = null;
        isNavigationUiOpen = true;
      });
    }

    notifyNavigationIconVisibility();

    try {
      final routeFeature = await _fetchRouteFeature(
        originLng: origin.longitude,
        originLat: origin.latitude,
        destinationLng: request.longitude,
        destinationLat: request.latitude,
      );

      await MapRouteDrawer.draw(
        mapboxMap: map,
        styleLoaded: styleLoaded,
        routeFeature: routeFeature,
      );

      await _animateToPoint(
        latitude: request.latitude,
        longitude: request.longitude,
        zoom: 14.5,
        pitch: 45.0,
        padding: MbxEdgeInsets(
          top: 140,
          left: 60,
          right: 60,
          bottom: 260,
        ),
      );

      startNavigationTracking(request);

      if (!mounted) {
        return;
      }

      _setNavigationUiOpen(false);
      notifyNavigationIconVisibility();
    } catch (error, stackTrace) {
      await locationService.stopNavigationTracking();
      activeNavigationRequest = null;

      if (!mounted) {
        return;
      }

      _setNavigationUiOpen(false);
      notifyNavigationIconVisibility();

      _logMapWarning(
        'Unable to start directions.',
        error: error,
        stackTrace: stackTrace,
      );

      _showMappedError(
        error,
        stackTrace: stackTrace,
        fallbackMessage: 'Unable to load route right now.',
      );
    } finally {
      _setFetchingRoute(false);
    }
  }

  Future<void> stopNavigation() async {
    await locationService.stopNavigationTracking();

    lastReroutePosition = null;
    isRerouting = false;

    final map = mapboxMap;

    if (map != null) {
      await MapRouteDrawer.clear(map);
    }

    activeNavigationRequest = null;

    if (!mounted) {
      return;
    }

    setState(() {
      isNavigationUiOpen = false;
      activeDirectionsRequest = null;
    });

    notifyNavigationIconVisibility();
    await centerOnUserPuck();
  }

  Future<void> openActiveNavigationUi() async {
    final request = activeNavigationRequest;

    if (request == null || mapboxMap == null) {
      return;
    }

    if (isNavigationUiOpen) {
      _setNavigationUiOpen(false);
      return;
    }

    await _animateToPoint(
      latitude: request.latitude,
      longitude: request.longitude,
      zoom: 14.5,
      pitch: 45.0,
      padding: MbxEdgeInsets(
        top: 140,
        left: 60,
        right: 60,
        bottom: 260,
      ),
      durationMs: 700,
    );

    if (mounted) {
      _setNavigationUiOpen(true);
    }
  }

  void returnToEventDetails(
    EventDirectionsRequest request,
  ) {
    if (!mounted) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventDetailsScreen(
          eventId: request.eventId,
          onCloseParentSearchSheet:
              widget.onCloseSearchOverlay,
        ),
      ),
    );
  }

  void _logMapWarning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    AppLogger.warning(message, tag: 'MapHomeScreen');

    if (error != null) {
      AppLogger.error(
        message,
        tag: 'MapHomeScreen',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _showMappedError(
    Object error, {
    StackTrace? stackTrace,
    String fallbackMessage = 'Something went wrong.',
  }) {
    _showMessage(
      ErrorMapper.toMessage(
        error,
        stackTrace: stackTrace,
        fallbackMessage: fallbackMessage,
      ),
    );
  }

  Future<void> _runMapTask(
    Future<void> Function() action, {
    required String debugLabel,
  }) async {
    try {
      await action();
    } catch (error, stackTrace) {
      _logMapWarning(
        debugLabel,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _animateToPoint({
    required double latitude,
    required double longitude,
    required double zoom,
    required double pitch,
    double bearing = 0.0,
    required MbxEdgeInsets padding,
    int durationMs = 900,
  }) async {
    final map = mapboxMap;

    if (map == null) {
      return;
    }

    await map.easeTo(
      CameraOptions(
        center: Point(
          coordinates: Position(
            longitude,
            latitude,
          ),
        ),
        zoom: zoom,
        pitch: pitch,
        bearing: bearing,
        padding: padding,
      ),
      MapAnimationOptions(
        duration: durationMs,
        startDelay: 0,
      ),
    );
  }

  void _setFetchingRoute(bool value) {
    if (!mounted) {
      return;
    }

    setState(() {
      isFetchingRoute = value;
    });
  }

  void clearDirectionsCard() {
    if (!mounted) {
      return;
    }

    setState(() {
      activeDirectionsRequest = null;
    });
  }

  void handleEventTap(int eventId) {
    widget.onEventSelected?.call(eventId);
  }

  void notifyNavigationIconVisibility() {
    widget.onNavigationUiVisibilityChanged?.call(
      activeNavigationRequest != null,
    );
  }

  Widget _buildMap(MapSettingsState settings) {
    return Positioned.fill(
      child: MapWidget(
        key: const ValueKey('geo-event-map'),
        textureView: true,
        styleUri: baseStyleUri,
        cameraOptions: CameraOptions(
          center: Point(
            coordinates: Position(
              defaultLng,
              defaultLat,
            ),
          ),
          zoom: settings.map3D ? cityZoom : baseZoom,
          bearing: 0.0,
          pitch: settings.map3D ? cityPitch : 0.0,
        ),
        onMapCreated: onMapCreated,
        onStyleLoadedListener: onStyleLoaded,
        onCameraChangeListener: (event) {
          final zoom = event.cameraState.zoom;
          final shouldResync =
              (zoom - _currentZoom).abs() >= 0.6;

          _currentZoom = zoom;

          if (shouldResync &&
              mounted &&
              !isSyncingPins) {
            unawaited(syncEventPins());
          }
        },
      ),
    );
  }

  Widget _buildLoadingOverlay(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: Theme.of(context)
              .colorScheme
              .surface
              .withValues(alpha: 0.18),
          child: const Center(
            child: AppLoadingIndicator(
              title: 'Loading map',
              message: 'Preparing pins and location data...',
              padding: EdgeInsets.all(24),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDirectionsCard() {
    final request = activeDirectionsRequest;

    if (request == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 16,
      right: 16,
      bottom: 20,
      child: SafeArea(
        top: false,
        child: DirectionsActionCard(
          title: request.title,
          isLoading: isFetchingRoute,
          onStartDirections: () => startDirections(request),
          onReturnToEventDetails: () =>
              returnToEventDetails(request),
          onClose: clearDirectionsCard,
        ),
      ),
    );
  }

  Widget _buildActiveNavigationCard(
    EventDirectionsRequest activeNavigation,
  ) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 20,
      child: SafeArea(
        top: false,
        child: ActiveNavigationCard(
          title: activeNavigation.title,
          onStopNavigation: stopNavigation,
          onViewEventDetails: () =>
              returnToEventDetails(activeNavigation),
          onClose: () {
            if (!mounted) {
              return;
            }

            setState(() {
              isNavigationUiOpen = false;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(
      mapSettingsControllerProvider,
    );

    final activeNavigation = ref.watch(
      activeNavigationProvider,
    );

    return Stack(
      children: [
        _buildMap(settings),
        if (_showMapLoadingOverlay)
          _buildLoadingOverlay(context),
        if (activeDirectionsRequest != null)
          _buildDirectionsCard(),
        if (activeNavigation != null && isNavigationUiOpen)
          _buildActiveNavigationCard(activeNavigation),
      ],
    );
  }
}