import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' hide Layer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../../core/config/app_env.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../shared/events/models/create_event_models.dart';
import '../../../../shared/events/models/event_map_pin_data.dart';
import '../../../../shared/events/providers/event_providers.dart';
import '../../../../shared/location/data/map_location_service.dart';
import '../../../../shared/location/data/map_pin_annotations_service.dart';
import '../../../../shared/location/data/map_route_service.dart';
import '../../../../shared/location/models/event_directions_request.dart';
import '../../../../shared/location/models/map_filter_selection.dart';
import '../../../../shared/location/providers/directions_providers.dart';
import '../../../../shared/profile/providers/profile_providers.dart';
import '../../../event/presentation/screens/event_detail_screen.dart';
import '../../application/map_settings_controller.dart';
import '../widgets/event_pin_marker.dart';
import '../widgets/map_navigation_cards.dart';

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
    } catch (_) {
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

  final locationService = MapLocationService();
  final routeService = MapRouteService();
  final pinService = MapPinAnnotationService();

  ProviderSubscription<MapSettingsState>? settingsSubscription;
  ProviderSubscription<EventDirectionsRequest?>? pendingDirectionsSubscription;

  Timer? pinsRefreshTimer;
  MapboxMap? mapboxMap;

  late List<EventMapPinData> events;
  final Map<String, GlobalKey> pinKeys = {};

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
  EventDirectionsRequest? activeNavigationRequest;

  double? currentLatitude;
  double? currentLongitude;
  double _currentZoom = baseZoom;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    AppEnv.validate();
    MapboxOptions.setAccessToken(AppEnv.mapboxToken);

    events = [];
    rebuildPinKeys();

    startHeadingTracking();
    listenToMapSettings();
    listenToPendingDirections();
    scheduleInitialLoad();
    startPinsAutoRefresh();
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

  void startPinsAutoRefresh() {
    pinsRefreshTimer?.cancel();
    pinsRefreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => reloadMapPins(silent: true),
    );
  }

  void startHeadingTracking() {
    locationService.startHeadingTracking(
      onHeading: (heading) => widget.onBearingChanged?.call(heading),
    );
  }

  void listenToMapSettings() {
    settingsSubscription?.close();
    settingsSubscription = ref.listenManual<MapSettingsState>(
      mapSettingsControllerProvider,
      (previous, next) async {
        if (previous == null) return;

        if (previous.map3D != next.map3D) {
          await applyStandardMapConfiguration(next);
          await animateCameraFor3D(next.map3D);
        }
        if (previous.terrain != next.terrain) {
          await applyTerrain(next.terrain);
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

  void listenToPendingDirections() {
    pendingDirectionsSubscription?.close();
    pendingDirectionsSubscription = ref.listenManual<EventDirectionsRequest?>(
      pendingDirectionsProvider,
      (_, next) async {
        if (next == null || handlingPendingDirections) return;
        await tryHandlePendingDirections(next);
      },
    );
  }

  bool get isReadyForPendingDirections =>
      mounted && mapboxMap != null && styleLoaded && captureReady;

  void showMessage(String message) {
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

  void scheduleInitialLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      setState(() => captureReady = true);
      await reloadMapPins();
      await consumeInitialPendingDirectionsIfNeeded();
    });
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

  Future<void> hideBuiltInCompass() async {
    if (mapboxMap == null) return;

    await mapboxMap!.compass.updateSettings(
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
    if (mapboxMap == null) return;

    await mapboxMap!.location.updateSettings(
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
      showMessage(locationService.messageForFailure(result.failure!));
    }

    return null;
  }

  Future<Position?> getUserPosition() async {
    if (mapboxMap == null) return null;

    final position = await mapboxMap!.style.getPuckPositionSafe();
    if (position != null) {
      currentLatitude = position.lat.toDouble();
      currentLongitude = position.lng.toDouble();
    }
    return position;
  }

  Future<void> onStyleLoaded(StyleLoadedEventData data) async {
    await hideBuiltInCompass();

    await pinService.prepare(
      mapboxMap: mapboxMap!,
      onEventTap: handleEventTap,
    );

    terrainSourceAdded = false;

    if (!mounted) return;
    setState(() => styleLoaded = true);

    final settings = ref.read(mapSettingsControllerProvider);
    await applyStandardMapConfiguration(settings);
    await applyTerrain(settings.terrain);
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

  Future<void> applyStandardMapConfiguration(MapSettingsState settings) async {
    if (mapboxMap == null || !styleLoaded) return;

    final style = mapboxMap!.style;

    try {
      await style.setStyleImportConfigProperty(
        'basemap',
        'lightPreset',
        settings.dayNightCycle ? resolveLightPreset() : 'day',
      );
    } catch (_) {}

    try {
      await style.setStyleImportConfigProperty(
        'basemap',
        'showPointOfInterestLabels',
        settings.mapPins,
      );
    } catch (_) {}

    try {
      await style.setStyleImportConfigProperty(
        'basemap',
        'showTransitLabels',
        settings.mapPins,
      );
    } catch (_) {}

    try {
      await style.setStyleImportConfigProperty(
        'basemap',
        'showPlaceLabels',
        true,
      );
    } catch (_) {}

    try {
      await style.setStyleImportConfigProperty(
        'basemap',
        'showRoadLabels',
        true,
      );
    } catch (_) {}

    try {
      await style.setStyleImportConfigProperty(
        'basemap',
        'show3dObjects',
        settings.map3D,
      );
    } catch (_) {}
  }

  Future<void> ensureTerrainSource() async {
    if (mapboxMap == null || !styleLoaded || terrainSourceAdded) return;

    try {
      await mapboxMap!.style.addSource(
        RasterDemSource(
          id: terrainSourceId,
          url: 'mapbox://mapbox.mapbox-terrain-dem-v1',
          tileSize: 512,
          maxzoom: 14,
        ),
      );
    } catch (_) {}

    terrainSourceAdded = true;
  }

  Future<void> applyTerrain(bool enabled) async {
    if (mapboxMap == null || !styleLoaded) return;

    await ensureTerrainSource();

    try {
      await mapboxMap!.style.setStyleTerrainProperty(
        'exaggeration',
        enabled ? terrainExaggeration : 0.0,
      );
    } catch (_) {}
  }

  Future<void> animateCameraFor3D(bool enabled) async {
    if (mapboxMap == null) return;

    await mapboxMap!.easeTo(
      CameraOptions(
        zoom: enabled ? cityZoom : baseZoom,
        pitch: enabled ? cityPitch : 0.0,
      ),
      MapAnimationOptions(duration: 550, startDelay: 0),
    );
  }

ui.Size pinSizeForPriority(EventPinPriority priority) {
  switch (priority) {
    case EventPinPriority.high:
      return const ui.Size(220, 150);
    case EventPinPriority.medium:
      return const ui.Size(190, 132);
    case EventPinPriority.low:
      return const ui.Size(160, 116);
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
      setState(() => isLoadingMapPins = true);
    }

    final pins = await fetchMapPins();
    if (!mounted) return;

    final oldSignature = events
        .map((e) => '${e.id}-${e.lat}-${e.lng}-${e.imageUrl}-${e.priority.name}')
        .join('|');
    final newSignature = pins
        .map((e) => '${e.id}-${e.lat}-${e.lng}-${e.imageUrl}-${e.priority.name}')
        .join('|');

    if (oldSignature == newSignature && !forceResync) {
      if (!silent) {
        setState(() => isLoadingMapPins = false);
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
    if (!settings.eventPins || !styleLoaded || !captureReady || events.isEmpty) {
      return;
    }

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

  Future<void> focusOnEventLocation({
    required double latitude,
    required double longitude,
  }) async {
    if (mapboxMap == null) return;

    final settings = ref.read(mapSettingsControllerProvider);

    await mapboxMap!.easeTo(
      CameraOptions(
        center: Point(coordinates: Position(longitude, latitude)),
        zoom: settings.map3D ? cityZoom : 15.8,
        pitch: settings.map3D ? cityPitch : 0.0,
        bearing: 0.0,
        padding: MbxEdgeInsets(top: 120, left: 40, right: 40, bottom: 260),
      ),
      MapAnimationOptions(duration: 900, startDelay: 0),
    );
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
      return;
    }

    if (!isReadyForPendingDirections) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    if (!isReadyForPendingDirections || !mounted) return;

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

  Future<void> applyEventPinsVisibility(bool visible) async {
    await pinService.clear();
    if (visible) {
      await tryAddEventPins();
    }
    if (!mounted) return;
    setState(() {});
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

  Future<void> centerOnUserPuck() async {
    if (mapboxMap == null) return;

    final puck = await getUserPosition();
    if (puck != null) {
      await mapboxMap!.easeTo(
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

    await mapboxMap!.easeTo(
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

  void notifyNavigationIconVisibility() {
    widget.onNavigationUiVisibilityChanged?.call(activeNavigationRequest != null);
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
          final routeGeoJson = await routeService.fetchRouteGeoJson(
            originLng: position.longitude,
            originLat: position.latitude,
            destinationLng: request.longitude,
            destinationLat: request.latitude,
          );

          await routeService.drawRouteLine(
            mapboxMap: mapboxMap!,
            styleLoaded: styleLoaded,
            routeFeature: routeGeoJson,
          );
        } catch (_) {
        } finally {
          isRerouting = false;
        }
      },
    );
  }

  Future<void> startDirections(EventDirectionsRequest request) async {
    final origin = await getCurrentDeviceLocation();
    if (origin == null || mapboxMap == null) return;

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
      final routeGeoJson = await routeService.fetchRouteGeoJson(
        originLng: origin.longitude,
        originLat: origin.latitude,
        destinationLng: request.longitude,
        destinationLat: request.latitude,
      );

      await routeService.drawRouteLine(
        mapboxMap: mapboxMap!,
        styleLoaded: styleLoaded,
        routeFeature: routeGeoJson,
      );

      await mapboxMap!.easeTo(
        CameraOptions(
          center: Point(
            coordinates: Position(request.longitude, request.latitude),
          ),
          zoom: 14.5,
          pitch: 45.0,
          bearing: 0.0,
          padding: MbxEdgeInsets(top: 140, left: 60, right: 60, bottom: 260),
        ),
        MapAnimationOptions(duration: 900, startDelay: 0),
      );

      startNavigationTracking(request);
      ref.read(activeNavigationProvider.notifier).state = request;
      isNavigationUiOpen = false;
      notifyNavigationIconVisibility();
    } catch (_) {
      await locationService.stopNavigationTracking();
      ref.read(activeNavigationProvider.notifier).state = null;

      if (!mounted) return;
      setState(() => activeNavigationRequest = null);

      isNavigationUiOpen = false;
      notifyNavigationIconVisibility();
      showMessage('Unable to load route right now.');
    } finally {
      if (mounted) {
        setState(() => isFetchingRoute = false);
      }
    }
  }

  Future<void> stopNavigation() async {
    await locationService.stopNavigationTracking();
    lastReroutePosition = null;
    isRerouting = false;

    if (mapboxMap != null) {
      await routeService.clearRouteLine(mapboxMap!);
    }

    if (!mounted) return;
    setState(() {
      activeNavigationRequest = null;
      isNavigationUiOpen = false;
      activeDirectionsRequest = null;
    });

    ref.read(activeNavigationProvider.notifier).state = null;
    notifyNavigationIconVisibility();
    await centerOnUserPuck();
  }

  Future<void> openActiveNavigationUi() async {
    final request = activeNavigationRequest;
    if (request == null || mapboxMap == null) return;

    if (isNavigationUiOpen) {
      if (!mounted) return;
      setState(() => isNavigationUiOpen = false);
      return;
    }

    await mapboxMap!.easeTo(
      CameraOptions(
        center: Point(
          coordinates: Position(request.longitude, request.latitude),
        ),
        zoom: 14.5,
        pitch: 45.0,
        bearing: 0.0,
        padding: MbxEdgeInsets(top: 140, left: 60, right: 60, bottom: 260),
      ),
      MapAnimationOptions(duration: 700, startDelay: 0),
    );

    if (!mounted) return;
    setState(() => isNavigationUiOpen = true);
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

  void clearDirectionsCard() {
    if (!mounted) return;
    setState(() => activeDirectionsRequest = null);
  }

  void handleEventTap(int eventId) {
    widget.onEventSelected?.call(eventId);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    pinsRefreshTimer?.cancel();
    settingsSubscription?.close();
    pendingDirectionsSubscription?.close();
    pinService.dispose();
    locationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(mapSettingsControllerProvider);

    return Stack(
      children: [
        Positioned.fill(
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
        ),
        buildHiddenMarkerLayer(),
        if (!styleLoaded || isLoadingMapPins)
          Positioned.fill(
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
          ),
        if (activeDirectionsRequest != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: SafeArea(
              top: false,
              child: DirectionsActionCard(
                title: activeDirectionsRequest!.title,
                isLoading: isFetchingRoute,
                onStartDirections: () => startDirections(activeDirectionsRequest!),
                onReturnToEventDetails: () =>
                    returnToEventDetails(activeDirectionsRequest!),
                onClose: clearDirectionsCard,
              ),
            ),
          ),
        if (activeNavigationRequest != null && isNavigationUiOpen)
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: SafeArea(
              top: false,
              child: ActiveNavigationCard(
                title: activeNavigationRequest!.title,
                onStopNavigation: stopNavigation,
                onViewEventDetails: () =>
                    returnToEventDetails(activeNavigationRequest!),
                onClose: () {
                  if (!mounted) return;
                  setState(() => isNavigationUiOpen = false);
                },
              ),
            ),
          ),
      ],
    );
  }
}