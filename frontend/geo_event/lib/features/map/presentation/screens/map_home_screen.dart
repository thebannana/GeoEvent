import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../../core/config/app_environment.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/feedback/app_loading_indicator.dart';
import '../../../../shared/events/models/create_event_models.dart';
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
import '../../../../shared/profile/providers/profile_providers.dart';
import '../../../event/presentation/screens/event_detail_screen.dart';
import '../../application/map_settings_controller.dart';
import '../widgets/active_navigation_card.dart';
import '../widgets/directions_action_card.dart';
import '../widgets/event_pin_marker.dart';

extension PuckPositionX on StyleManager {
  Future<Position?> getPuckPositionSafe() async {
    try {
      final Layer? layer = Platform.isAndroid
          ? await getLayer('mapbox-location-indicator-layer')
          : await getLayer('puck');

      if (layer is! LocationIndicatorLayer) return null;

      final location = layer.location;
      if (location == null || location.length < 2) return null;

      return Position(
        (location[1] ?? 0).toDouble(),
        (location[0] ?? 0).toDouble(),
      );
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Unable to read puck position.',
        tag: 'MapHomeScreen',
      );
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
  static const String terrainSourceId = 'geoevent-terrain-source';
  static const double baseZoom = 13.0;
  static const double cityZoom = 15.5;
  static const double cityPitch = 60.0;
  static const double terrainExaggeration = 1.55;
  static const double defaultLng = 18.4131;
  static const double defaultLat = 43.8563;

  final MapLocationService locationService = MapLocationService();
  final MapPinAnnotationService pinService = MapPinAnnotationService();

  ProviderSubscription<MapSettingsState>? settingsSubscription;
  ProviderSubscription<EventDirectionsRequest?>? pendingDirectionsSubscription;
  ProviderSubscription<int>? eventRefreshSubscription;

  Timer? pinsRefreshTimer;
  MapboxMap? mapboxMap;

  List<EventMapPinData> events = [];
  final Map<int, GlobalKey> pinKeys = {};

  bool styleLoaded = false;
  bool captureReady = false;
  bool terrainSourceAdded = false;
  bool isLoadingMapPins = false;
  bool isSyncingPins = false;
  bool handlingPendingDirections = false;
  bool hasHandledInitialPendingDirections = false;
  bool isFetchingRoute = false;
  bool isNavigationUiOpen = false;

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
    MapboxOptions.setAccessToken(AppEnvironment.mapboxAccessToken);

    rebuildPinKeys();
    _startHeadingTracking();
    _listenToMapSettings();
    _listenToPendingDirections();
    _listenToEventRefresh();
    _scheduleInitialLoad();
    _startPinsAutoRefresh();
  }

  @override
  void didUpdateWidget(covariant MapHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filterSelection != widget.filterSelection) {
      reloadMapPins();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      reloadMapPins();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    pinsRefreshTimer?.cancel();
    settingsSubscription?.close();
    pendingDirectionsSubscription?.close();
    eventRefreshSubscription?.close();
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
      onHeading: (heading) => widget.onBearingChanged?.call(heading),
    );
  }

  void _listenToMapSettings() {
    settingsSubscription?.close();
    settingsSubscription = ref.listenManual<MapSettingsState>(
      mapSettingsControllerProvider,
      (previous, next) async {
        if (previous == null) return;

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
    pendingDirectionsSubscription = ref.listenManual<EventDirectionsRequest?>(
      pendingDirectionsProvider,
      (_, next) async {
        if (next == null || handlingPendingDirections) return;
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
    if (!mounted) return;
    setState(() => isLoadingMapPins = value);
  }

  void _setNavigationUiOpen(bool value) {
    if (!mounted) return;
    setState(() => isNavigationUiOpen = value);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void rebuildPinKeys() {
    pinKeys
      ..clear()
      ..addEntries(events.map((event) => MapEntry(event.id, GlobalKey())));
  }

  Future<void> onMapCreated(MapboxMap createdMap) async {
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

  Future<void> onStyleLoaded(StyleLoadedEventData data) async {
    final map = mapboxMap;
    if (map == null) return;

    await hideBuiltInCompass();

    await pinService.prepare(
      mapboxMap: map,
      onEventTap: handleEventTap,
    );

    terrainSourceAdded = false;

    if (!mounted) return;
    setState(() => styleLoaded = true);

    final settings = ref.read(mapSettingsControllerProvider);
    await applyStandardMapConfiguration(settings);
    await applyEventPinsVisibility(settings.eventPins);
    await reloadMapPins(silent: true, forceResync: true);
    await consumeInitialPendingDirectionsIfNeeded();
  }

  String get baseStyleUri => MapboxStyles.STANDARD;

  String resolveLightPreset() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 8) return 'dawn';
    if (hour >= 8 && hour < 18) return 'day';
    if (hour >= 18 && hour < 20) return 'dusk';
    return 'night';
  }

  Future<void> hideBuiltInCompass() async {
    final map = mapboxMap;
    if (map == null) return;

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
    if (map == null) return;

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

    if (result.failure != null) {
      _showMessage(locationService.messageForFailure(result.failure!));
    }

    return null;
  }

  Future<Position?> getUserPosition() async {
    final map = mapboxMap;
    if (map == null) return null;

    final position = await map.style.getPuckPositionSafe();
    if (position != null) {
      currentLatitude = position.lat.toDouble();
      currentLongitude = position.lng.toDouble();
    }
    return position;
  }

  Future<void> applyStandardMapConfiguration(MapSettingsState settings) async {
  final map = mapboxMap;
  if (map == null || !styleLoaded) return;

  final style = map.style;

  await _runMapTask(
    () => style.setStyleImportConfigProperty(
      'basemap',
      'lightPreset',
      settings.dayNightCycle ? resolveLightPreset() : 'day',
    ),
    debugLabel: 'Failed to apply map light preset.',
  );

  await _runMapTask(
    () => style.setStyleImportConfigProperty(
      'basemap',
      'showPointOfInterestLabels',
      settings.mapPins,
    ),
    debugLabel: 'Failed to apply point-of-interest labels visibility.',
  );

  await _runMapTask(
    () => style.setStyleImportConfigProperty(
      'basemap',
      'showTransitLabels',
      settings.mapPins,
    ),
    debugLabel: 'Failed to apply transit labels visibility.',
  );

  await _runMapTask(
    () => style.setStyleImportConfigProperty(
      'basemap',
      'showPlaceLabels',
      true,
    ),
    debugLabel: 'Failed to apply place labels visibility.',
  );

  await _runMapTask(
    () => style.setStyleImportConfigProperty(
      'basemap',
      'showRoadLabels',
      true,
    ),
    debugLabel: 'Failed to apply road labels visibility.',
  );

  await _runMapTask(
    () => style.setStyleImportConfigProperty(
      'basemap',
      'show3dObjects',
      settings.map3D,
    ),
    debugLabel: 'Failed to apply 3D objects visibility.',
  );
}

  Future<void> animateCameraFor3D(bool enabled) async {
    final map = mapboxMap;
    if (map == null) return;

    await map.easeTo(
      CameraOptions(
        zoom: enabled ? cityZoom : baseZoom,
        pitch: enabled ? cityPitch : 0.0,
      ),
      MapAnimationOptions(duration: 550, startDelay: 0),
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
    padding: MbxEdgeInsets(top: 120, left: 40, right: 40, bottom: 260),
  );
}

  Future<void> centerOnUserPuck() async {
    final map = mapboxMap;
    if (map == null) return;

    final puck = await getUserPosition();
    if (puck != null) {
      await map.easeTo(
        CameraOptions(
          center: Point(
            coordinates: Position(puck.lng.toDouble(), puck.lat.toDouble()),
          ),
          zoom: 16.0,
          pitch: 0.0,
          bearing: 0.0,
        ),
        MapAnimationOptions(duration: 700, startDelay: 0),
      );
      return;
    }

    final gps = await getCurrentDeviceLocation();
    if (gps == null) return;

    await map.easeTo(
      CameraOptions(
        center: Point(
          coordinates: Position(gps.longitude, gps.latitude),
        ),
        zoom: 16.0,
        pitch: 0.0,
        bearing: 0.0,
      ),
      MapAnimationOptions(duration: 700, startDelay: 0),
    );
  }

  ui.Size pinSizeForPriority(EventPinPriority priority) {
    switch (priority) {
      case EventPinPriority.high:
        return const ui.Size(220, 150);
      case EventPinPriority.medium:
        return const ui.Size(196, 136);
      case EventPinPriority.low:
        return const ui.Size(176, 124);
    }
  }

  List<EventMapPinData> visiblePinsForZoom({
    required List<EventMapPinData> pins,
    required double zoom,
  }) {
    if (zoom >= 15) return pins;

    final maxCount = zoom >= 13.5
        ? 40
        : zoom >= 12
            ? 20
            : 10;

    final filtered = pins.where((pin) {
      if (zoom < 12) return pin.priority == EventPinPriority.high;
      if (zoom < 13.5) return pin.priority != EventPinPriority.low;
      return true;
    }).toList();

    return filtered.take(maxCount).toList();
  }

  Future<List<EventMapPinData>> fetchMapPins() async {
    try {
      final filters = widget.filterSelection;
      final api = ref.read(eventsApiProvider);

      final devicePosition = await getCurrentDeviceLocation();
      final userLat = devicePosition?.latitude ?? currentLatitude ?? defaultLat;
      final userLng = devicePosition?.longitude ?? currentLongitude ?? defaultLng;

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
            );

      final preferredSegmentIds = ref.read(preferredSegmentIdsProvider);
      final preferredGenreIds = ref.read(preferredGenreIdsProvider);
      final preferredSubGenreIds = ref.read(preferredSubGenreIdsProvider);

      final scoredItems = items.map((item) {
        final score = filters.usePreferences
            ? mapRecommendationScore(
                item: item,
                userLatitude: userLat,
                userLongitude: userLng,
                preferredSegmentIds: preferredSegmentIds,
                preferredGenreIds: preferredGenreIds,
                preferredSubGenreIds: preferredSubGenreIds,
              )
            : 0;

        return (item: item, score: score);
      }).toList();

      scoredItems.sort((a, b) => b.score.compareTo(a.score));

      return scoredItems
          .map(
            (e) => EventMapPinData.fromEventItem(
              e.item,
              recommendationScore: e.score,
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> reloadMapPins({
    bool silent = false,
    bool forceResync = false,
  }) async {
    if (!mounted || isSyncingPins) return;

    if (!silent) {
      _setLoadingPins(true);
    }

    final pins = await fetchMapPins();
    if (!mounted) return;

    final oldSignature = events
        .map(
          (e) =>
              '${e.id}-${e.lat}-${e.lng}-${e.imageUrl}-${e.priority.name}-${e.categoryColor.value}',
        )
        .join('|');

    final newSignature = pins
        .map(
          (e) =>
              '${e.id}-${e.lat}-${e.lng}-${e.imageUrl}-${e.priority.name}-${e.categoryColor.value}',
        )
        .join('|');

    if (oldSignature == newSignature && !forceResync) {
      if (!silent) {
        _setLoadingPins(false);
      }
      return;
    }

    setState(() {
      events = pins;
      rebuildPinKeys();
      if (!silent) {
        isLoadingMapPins = false;
      }
    });

    await pinService.precacheMarkerImages(context, events);
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 180));

    if (!mounted) return;
    await syncEventPins();
  }

  Future<void> syncEventPins() async {
    final settings = ref.read(mapSettingsControllerProvider);
    if (!settings.eventPins || !_canSyncPins) return;

    isSyncingPins = true;

    try {
      final visiblePins = visiblePinsForZoom(
        pins: events,
        zoom: _currentZoom,
      );

      await pinService.syncPins(
        events: visiblePins,
        capturePinBytes: (eventId) async {
          final key = pinKeys[eventId];
          if (key == null) return null;
          return pinService.capturePinBytes(key: key);
        },
      );
    } finally {
      isSyncingPins = false;
      if (!mounted) return;
      setState(() {});
    }
  }

  Future<void> tryAddEventPins() async {
    await syncEventPins();
  }

  Future<void> applyEventPinsVisibility(bool visible) async {
    await pinService.clear();
    if (visible) {
      await tryAddEventPins();
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> tryHandlePendingDirections(EventDirectionsRequest request) async {
    if (activeNavigationRequest?.eventId == request.eventId) {
      ref.read(pendingDirectionsProvider.notifier).state = null;

      if (mounted) {
        setState(() {
          isNavigationUiOpen = true;
          activeDirectionsRequest = null;
        });
      }

      notifyNavigationIconVisibility();
      return;
    }

    if (!_isReadyForPendingDirections) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    if (!_isReadyForPendingDirections || !mounted) return;

    handlingPendingDirections = true;
    try {
      await focusOnEventLocation(
        latitude: request.latitude,
        longitude: request.longitude,
      );

      if (!mounted) return;
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
    if (hasHandledInitialPendingDirections) return;

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

  void startNavigationTracking(EventDirectionsRequest request) {
  lastReroutePosition = null;
  isRerouting = false;

  locationService.startNavigationTracking(
    onPosition: (position) async {
      currentLatitude = position.latitude;
      currentLongitude = position.longitude;

      if (isRerouting) return;

      final last = lastReroutePosition;
      final movedEnough = last == null ||
          geo.Geolocator.distanceBetween(
                last.latitude,
                last.longitude,
                position.latitude,
                position.longitude,
              ) >=
              25;

      if (!movedEnough || mapboxMap == null) return;

      isRerouting = true;
      lastReroutePosition = position;

      try {
        final routeFeature = await _fetchRouteFeature(
          originLng: position.longitude,
          originLat: position.latitude,
          destinationLng: request.longitude,
          destinationLat: request.latitude,
        );

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

  Future<void> startDirections(EventDirectionsRequest request) async {
  final origin = await getCurrentDeviceLocation();
  final map = mapboxMap;
  if (origin == null || map == null) return;

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
      padding: MbxEdgeInsets(top: 140, left: 60, right: 60, bottom: 260),
    );

    startNavigationTracking(request);

    if (!mounted) return;
    _setNavigationUiOpen(false);
    notifyNavigationIconVisibility();
  } catch (error, stackTrace) {
    await locationService.stopNavigationTracking();
    activeNavigationRequest = null;

    if (!mounted) return;
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

    if (!mounted) return;
    setState(() {
      isNavigationUiOpen = false;
      activeDirectionsRequest = null;
    });

    notifyNavigationIconVisibility();
    await centerOnUserPuck();
  }

  Future<void> openActiveNavigationUi() async {
  final request = activeNavigationRequest;
  if (request == null || mapboxMap == null) return;

  if (isNavigationUiOpen) {
    _setNavigationUiOpen(false);
    return;
  }

  await _animateToPoint(
    latitude: request.latitude,
    longitude: request.longitude,
    zoom: 14.5,
    pitch: 45.0,
    padding: MbxEdgeInsets(top: 140, left: 60, right: 60, bottom: 260),
    durationMs: 700,
  );

  _setNavigationUiOpen(true);
}

  void returnToEventDetails(EventDirectionsRequest request) {
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventDetailsScreen(
          eventId: request.eventId,
          onCloseParentSearchSheet: widget.onCloseSearchOverlay,
        ),
      ),
    );
  }

  void _logMapWarning(
  String message, {
  Object? error,
  StackTrace? stackTrace,
}) {
  AppLogger.warning(
    message,
    tag: 'MapHomeScreen',
  );

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
  if (map == null) return;

  await map.easeTo(
    CameraOptions(
      center: Point(
        coordinates: Position(longitude, latitude),
      ),
      zoom: zoom,
      pitch: pitch,
      bearing: bearing,
      padding: padding,
    ),
    MapAnimationOptions(duration: durationMs, startDelay: 0),
  );
}

void _setFetchingRoute(bool value) {
  if (!mounted) return;
  setState(() => isFetchingRoute = value);
}

  void clearDirectionsCard() {
    if (!mounted) return;
    setState(() => activeDirectionsRequest = null);
  }

  void handleEventTap(int eventId) {
    widget.onEventSelected?.call(eventId);
  }

  void notifyNavigationIconVisibility() {
    widget.onNavigationUiVisibilityChanged
        ?.call(activeNavigationRequest != null);
  }

  Widget buildHiddenMarkerLayer() {
    return Positioned(
      left: -10000,
      top: 0,
      child: IgnorePointer(
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: events.map((event) {
              final size = pinSizeForPriority(event.priority);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RepaintBoundary(
                  key: pinKeys[event.id],
                  child: EventPinMarker(
                    title: event.title,
                    imageUrl: event.imageUrl ?? '',
                    color: event.categoryColor,
                    width: size.width,
                    height: size.height,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMap(MapSettingsState settings) {
  return Positioned.fill(
    child: MapWidget(
      key: const ValueKey('geo-event-map'),
      textureView: true,
      styleUri: baseStyleUri,
      cameraOptions: CameraOptions(
        center: Point(coordinates: Position(defaultLng, defaultLat)),
        zoom: settings.map3D ? cityZoom : baseZoom,
        bearing: 0.0,
        pitch: settings.map3D ? cityPitch : 0.0,
      ),
      onMapCreated: onMapCreated,
      onStyleLoadedListener: onStyleLoaded,
      onCameraChangeListener: (event) async {
        final zoom = event.cameraState.zoom;
        final shouldResync = (zoom - _currentZoom).abs() >= 0.6;
        _currentZoom = zoom;

        if (shouldResync && mounted && !isSyncingPins) {
          await syncEventPins();
        }
      },
    ),
  );
}

  Widget _buildLoadingOverlay(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.18),
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
    if (request == null) return const SizedBox.shrink();

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
          onReturnToEventDetails: () => returnToEventDetails(request),
          onClose: clearDirectionsCard,
        ),
      ),
    );
  }

  Widget _buildActiveNavigationCard(EventDirectionsRequest activeNavigation) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 20,
      child: SafeArea(
        top: false,
        child: ActiveNavigationCard(
          title: activeNavigation.title,
          onStopNavigation: stopNavigation,
          onViewEventDetails: () => returnToEventDetails(activeNavigation),
          onClose: () {
            if (!mounted) return;
            setState(() => isNavigationUiOpen = false);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(mapSettingsControllerProvider);
    final activeNavigation = ref.watch(activeNavigationProvider);

    return Stack(
      children: [
        _buildMap(settings),
        buildHiddenMarkerLayer(),
        if (_showMapLoadingOverlay) _buildLoadingOverlay(context),
        if (activeDirectionsRequest != null) _buildDirectionsCard(),
        if (activeNavigation != null && isNavigationUiOpen)
          _buildActiveNavigationCard(activeNavigation),
      ],
    );
  }
}