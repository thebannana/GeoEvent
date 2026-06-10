import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' hide Layer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;

import '../../../../core/config/app_env.dart';
import '../../../../shared/events/models/event_map_pin_data.dart';
import '../../../../shared/events/providers/event_providers.dart';
import '../../../../shared/location/models/event_directions_request.dart';
import '../../../../shared/location/providers/directions_providers.dart';
import '../../../event/presentation/screens/event_detail_screen.dart';
import '../../application/map_settings_controller.dart';
import '../widgets/event_pin_marker.dart';
import '../widgets/map_filter_panel.dart';

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
  static const ui.Size pinLogicalSize = ui.Size(190, 132);
  static const String terrainSourceId = 'geoevent-terrain-source';
  static const String routeSourceId = 'geoevent-route-source';
  static const String routeLayerId = 'geoevent-route-layer';
  static const Color routeLineColor = Color(0xFF199DFF);
  static const double routeLineWidth = 8.5;

  static const double baseZoom = 13.0;
  static const double cityZoom = 15.5;
  static const double cityPitch = 60.0;
  static const double terrainExaggeration = 1.55;
  static const double defaultLng = 18.4131;
  static const double defaultLat = 43.8563;

  StreamSubscription<geo.Position>? _navigationPositionSub;
  StreamSubscription<geo.Position>? _headingPositionSub;
  geo.Position? _lastReroutePosition;
  bool _isRerouting = false;

  MapboxMap? mapboxMap;
  PointAnnotationManager? pointAnnotationManager;

  ProviderSubscription<MapSettingsState>? settingsSubscription;
  ProviderSubscription<EventDirectionsRequest?>? pendingDirectionsSubscription;
  Timer? pinsRefreshTimer;

  bool styleLoaded = false;
  bool captureReady = false;
  bool terrainSourceAdded = false;
  bool isLoadingMapPins = false;
  bool isSyncingPins = false;
  bool handlingPendingDirections = false;
  bool hasHandledInitialPendingDirections = false;
  bool isFetchingRoute = false;
  bool isNavigationUiOpen = false;

  final Map<String, GlobalKey> pinKeys = {};
  final Map<String, int> annotationEventIds = {};
  late List<EventMapPinData> events;

  EventDirectionsRequest? activeDirectionsRequest;
  EventDirectionsRequest? activeNavigationRequest;

  double? currentLatitude;
  double? currentLongitude;

  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppEnv.validate();
    MapboxOptions.setAccessToken(AppEnv.mapboxToken);
    startHeadingTracking();

    events = [];
    rebuildPinKeys();
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
  _headingPositionSub?.cancel();

  const settings = geo.LocationSettings(
    accuracy: geo.LocationAccuracy.bestForNavigation,
    distanceFilter: 0,
  );

  _headingPositionSub =
      geo.Geolocator.getPositionStream(locationSettings: settings).listen(
    (position) {
      final heading = position.heading;
      if (heading.isNaN) return;
      widget.onBearingChanged?.call(heading);
    },
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

        if (previous.dayNightCycle != next.dayNightCycle) {
          await applyStandardMapConfiguration(next);
        }

        if (previous.mapPins != next.mapPins) {
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
      (previous, next) async {
        if (next == null || handlingPendingDirections) return;
        await tryHandlePendingDirections(next);
      },
    );
  }

  bool get isReadyForPendingDirections =>
      mounted && mapboxMap != null && styleLoaded && captureReady;

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

  void rebuildPinKeys() {
    pinKeys
      ..clear()
      ..addEntries(events.map((event) => MapEntry(event.id, GlobalKey())));
  }

  void onMapCreated(MapboxMap createdMap) async {
    mapboxMap = createdMap;
    widget.onMapReady?.call(createdMap);

    await hideBuiltInCompass();
    await enableUserLocation();
    await prepareAnnotations();
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

 Future<void> openActiveNavigationUi() async {
  final request = activeNavigationRequest;
  if (request == null || mapboxMap == null) return;

  if (isNavigationUiOpen) {
    if (!mounted) return;
    setState(() {
      isNavigationUiOpen = false;
    });
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
      padding: MbxEdgeInsets(
        top: 140,
        left: 60,
        right: 60,
        bottom: 260,
      ),
    ),
    MapAnimationOptions(duration: 700, startDelay: 0),
  );

  if (!mounted) return;
  setState(() {
    isNavigationUiOpen = true;
  });
}

  Future<geo.Position?> getCurrentDeviceLocation() async {
  try {
    final serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    debugPrint('Location service enabled: $serviceEnabled');

    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location services are disabled. Please enable GPS.'),
          ),
        );
      }
      return null;
    }

    var permission = await geo.Geolocator.checkPermission();
    debugPrint('Location permission before request: $permission');

    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
      debugPrint('Location permission after request: $permission');
    }

    if (permission == geo.LocationPermission.denied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission was denied.'),
          ),
        );
      }
      return null;
    }

    if (permission == geo.LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is permanently denied. Enable it in Settings.'),
          ),
        );
      }
      return null;
    }

    geo.Position? lastKnown = await geo.Geolocator.getLastKnownPosition();
    debugPrint('Last known position: $lastKnown');

    try {
      final position = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      debugPrint('Current position: ${position.latitude}, ${position.longitude}');
      currentLatitude = position.latitude;
      currentLongitude = position.longitude;
      return position;
    } catch (e) {
      debugPrint('getCurrentPosition failed, fallback to lastKnown: $e');

      if (lastKnown != null) {
        currentLatitude = lastKnown.latitude;
        currentLongitude = lastKnown.longitude;
        return lastKnown;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to determine your position. Try moving outdoors or enabling device location.'),
          ),
        );
      }
      return null;
    }
  } catch (e) {
    debugPrint('getCurrentDeviceLocation error: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location error: $e'),
        ),
      );
    }
    return null;
  }
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

  Future<void> prepareAnnotations() async {
    if (mapboxMap == null || pointAnnotationManager != null) return;

    pointAnnotationManager =
        await mapboxMap!.annotations.createPointAnnotationManager();
    await pointAnnotationManager!.setIconAllowOverlap(true);
    await pointAnnotationManager!.setTextAllowOverlap(true);
    await pointAnnotationManager!.setIconIgnorePlacement(true);
    await pointAnnotationManager!.setTextIgnorePlacement(true);

    pointAnnotationManager!.addOnPointAnnotationClickListener(
      MapPinClickListener(
        onTap: (annotation) {
          final eventId = annotationEventIds[annotation.id];
          if (eventId == null || !mounted) return;
          handleEventTap(eventId);
        },
      ),
    );
  }

  Future<void> onStyleLoaded(StyleLoadedEventData data) async {
    await hideBuiltInCompass();
    await prepareAnnotations();

    terrainSourceAdded = false;

    if (!mounted) return;
    setState(() {
      styleLoaded = true;
    });

    final settings = ref.read(mapSettingsControllerProvider);
    await applyStandardMapConfiguration(settings);
    await applyTerrain(settings.terrain);
    await applyEventPinsVisibility(settings.eventPins);
    await reloadMapPins(silent: true, forceResync: true);

    await consumeInitialPendingDirectionsIfNeeded();
  }

  void onCameraChange(CameraChangedEventData event) {}

  void scheduleInitialLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      setState(() {
        captureReady = true;
      });
      await reloadMapPins();
      await consumeInitialPendingDirectionsIfNeeded();
    });
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

    try {
      await mapboxMap!.style.setStyleImportConfigProperty(
        'basemap',
        'lightPreset',
        settings.dayNightCycle ? resolveLightPreset() : 'day',
      );
    } catch (_) {}

    try {
      await mapboxMap!.style.setStyleImportConfigProperty(
        'basemap',
        'showPointOfInterestLabels',
        settings.mapPins,
      );
    } catch (_) {}

    try {
      await mapboxMap!.style.setStyleImportConfigProperty(
        'basemap',
        'showTransitLabels',
        settings.mapPins,
      );
    } catch (_) {}

    try {
      await mapboxMap!.style.setStyleImportConfigProperty(
        'basemap',
        'showPlaceLabels',
        true,
      );
    } catch (_) {}

    try {
      await mapboxMap!.style.setStyleImportConfigProperty(
        'basemap',
        'showRoadLabels',
        true,
      );
    } catch (_) {}

    try {
      await mapboxMap!.style.setStyleImportConfigProperty(
        'basemap',
        'show3dObjects',
        settings.map3D,
      );
    } catch (_) {}

    if (activeNavigationRequest != null) {
  try {
    await mapboxMap!.style.setStyleLayerProperty(
      routeLayerId,
      'line-color',
      routeLineColor.value,
    );
    await mapboxMap!.style.setStyleLayerProperty(routeLayerId, 'line-opacity', 1.0);
    await mapboxMap!.style.setStyleLayerProperty(routeLayerId, 'line-width', routeLineWidth);
  } catch (_) {}
}
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

    final exaggeration = enabled ? terrainExaggeration : 0.0;

    try {
      await mapboxMap!.style.setStyleTerrainProperty(
        'exaggeration',
        exaggeration,
      );
    } catch (e) {
      debugPrint('applyTerrain failed: $e');
    }
  }

  Future<void> animateCameraFor3D(bool enabled) async {
    if (mapboxMap == null) return;

    await mapboxMap!.easeTo(
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
    if (mapboxMap == null) return;

    final settings = ref.read(mapSettingsControllerProvider);

    await mapboxMap!.easeTo(
      CameraOptions(
        center: Point(coordinates: Position(longitude, latitude)),
        zoom: settings.map3D ? cityZoom : 15.8,
        pitch: settings.map3D ? cityPitch : 0.0,
        bearing: 0.0,
        padding: MbxEdgeInsets(
          top: 120,
          left: 40,
          right: 40,
          bottom: 260,
        ),
      ),
      MapAnimationOptions(
        duration: 900,
        startDelay: 0,
      ),
    );
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
    if (pointAnnotationManager == null) return;

    await pointAnnotationManager!.deleteAll();
    annotationEventIds.clear();

    if (visible) {
      await tryAddEventPins();
    }

    if (!mounted) return;
    setState(() {});
  }

  Future<void> reloadMapPins({
    bool silent = false,
    bool forceResync = false,
  }) async {
    if (!mounted || isSyncingPins) return;

    if (!silent) {
      setState(() {
        isLoadingMapPins = true;
      });
    }

    final pins = await fetchMapPins();

    if (!mounted) return;

    final oldSignature =
        events.map((e) => '${e.id}:${e.lat}:${e.lng}:${e.imageUrl}').join('|');
    final newSignature =
        pins.map((e) => '${e.id}:${e.lat}:${e.lng}:${e.imageUrl}').join('|');
    final hasChanged = oldSignature != newSignature;

    if (!hasChanged && !forceResync) {
      if (!silent && mounted) {
        setState(() {
          isLoadingMapPins = false;
        });
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

    await precacheMarkerImages();
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 180));

    if (!mounted) return;
    await syncEventPins();
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

      return items.map(EventMapPinData.fromEventItem).toList();
    } catch (e) {
      debugPrint('fetchMapPins error: $e');
      return [];
    }
  }

void startNavigationTracking(EventDirectionsRequest request) {
  _navigationPositionSub?.cancel();
  _lastReroutePosition = null;

  const settings = geo.LocationSettings(
    accuracy: geo.LocationAccuracy.bestForNavigation,
    distanceFilter: 10,
  );

  _navigationPositionSub =
      geo.Geolocator.getPositionStream(locationSettings: settings).listen(
    (position) async {
      currentLatitude = position.latitude;
      currentLongitude = position.longitude;

      if (_isRerouting) return;

      final last = _lastReroutePosition;
      final movedEnough = last == null ||
          geo.Geolocator.distanceBetween(
                last.latitude,
                last.longitude,
                position.latitude,
                position.longitude,
              ) >=
              25;

      if (!movedEnough) return;

      _isRerouting = true;
      _lastReroutePosition = position;

      try {
        final routeGeoJson = await fetchRouteGeoJson(
          originLng: position.longitude,
          originLat: position.latitude,
          destinationLng: request.longitude,
          destinationLat: request.latitude,
        );

        await drawRouteLine(routeGeoJson);
      } catch (e) {
        debugPrint('reroute error $e');
      } finally {
        _isRerouting = false;
      }
    },
  );
}

  Future<void> syncEventPins() async {
    if (pointAnnotationManager == null) return;

    await pointAnnotationManager!.deleteAll();
    annotationEventIds.clear();
    await tryAddEventPins();

    if (!mounted) return;
    setState(() {});
  }

  Future<void> tryAddEventPins() async {
    final settings = ref.read(mapSettingsControllerProvider);

    if (isSyncingPins) return;
    if (!settings.eventPins) return;
    if (!styleLoaded || !captureReady) return;
    if (pointAnnotationManager == null) return;
    if (events.isEmpty) return;

    isSyncingPins = true;

    try {
      final eventIdsForOptions = <int>[];
      final options = <PointAnnotationOptions>[];

      for (final event in events) {
        final bytes = await capturePinBytes(event.id);
        if (bytes == null) continue;

        final parsedEventId = int.tryParse(event.id);
        if (parsedEventId == null) continue;

        options.add(
          PointAnnotationOptions(
            geometry: Point(coordinates: Position(event.lng, event.lat)),
            image: bytes,
            iconAnchor: IconAnchor.BOTTOM,
            iconOffset: [0.0, -6.0],
          ),
        );

        eventIdsForOptions.add(parsedEventId);
      }

      if (options.isEmpty) return;

      final annotations = await pointAnnotationManager!.createMulti(options);

      for (var i = 0; i < annotations.length; i++) {
        final annotationId = annotations[i]?.id;
        if (annotationId == null) continue;
        annotationEventIds[annotationId] = eventIdsForOptions[i];
      }
    } catch (e) {
      debugPrint('tryAddEventPins failed: $e');
    } finally {
      isSyncingPins = false;
    }
  }

  Future<void> precacheMarkerImages() async {
    for (final event in events) {
      final url = (event.imageUrl ?? '').trim();
      if (url.isEmpty) continue;

      try {
        await precacheImage(
          NetworkImage(url),
          context,
          onError: (_, __) {},
        );
      } catch (_) {}
    }
  }

  Future<Uint8List?> capturePinBytes(String eventId) async {
    final key = pinKeys[eventId];

    for (var i = 0; i < 30; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 32));

      final markerContext = key?.currentContext;
      if (markerContext == null) continue;

      final boundary = markerContext.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null || boundary.debugNeedsPaint) continue;

      try {
        final image = await boundary.toImage(pixelRatio: 3.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();

        final bytes = byteData?.buffer.asUint8List();
        if (bytes != null && bytes.isNotEmpty) return bytes;
      } catch (_) {
        debugPrint('Pin capture failed for eventId=$eventId');
      }
    }

    return null;
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
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RepaintBoundary(
                  key: pinKeys[event.id],
                  child: EventPinMarker(
                    title: event.title,
                    imageUrl: event.imageUrl ?? '',
                    color: event.categoryColor,
                    width: pinLogicalSize.width,
                    height: pinLogicalSize.height,
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
          coordinates: Position(
            puck.lng.toDouble(),
            puck.lat.toDouble(),
          ),
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

Future<void> drawRouteLine(Map<String, dynamic> routeFeature) async {
  if (mapboxMap == null || !styleLoaded) return;

  final style = mapboxMap!.style;
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

  await enableUserLocation();
}

void _notifyNavigationIconVisibility() {
  widget.onNavigationUiVisibilityChanged?.call(activeNavigationRequest != null);
}

  Future<void> clearRouteLine() async {
    if (mapboxMap == null) return;

    try {
      await mapboxMap!.style.removeStyleLayer(routeLayerId);
    } catch (_) {}

    try {
      await mapboxMap!.style.removeStyleSource(routeSourceId);
    } catch (_) {}
  }

  Future<void> startDirections(EventDirectionsRequest request) async {
  final origin = await getCurrentDeviceLocation();

  if (origin == null || mapboxMap == null) {
    return;
  }

  await _navigationPositionSub?.cancel();
  _navigationPositionSub = null;
  _lastReroutePosition = origin;
  _isRerouting = false;

if (mounted) {
  setState(() {
    isFetchingRoute = true;
    activeNavigationRequest = request;
    activeDirectionsRequest = null;
    isNavigationUiOpen = true;
  });
  _notifyNavigationIconVisibility();
}

  try {
    final routeGeoJson = await fetchRouteGeoJson(
      originLng: origin.longitude,
      originLat: origin.latitude,
      destinationLng: request.longitude,
      destinationLat: request.latitude,
    );

    await drawRouteLine(routeGeoJson);

    await mapboxMap!.easeTo(
      CameraOptions(
        center: Point(
          coordinates: Position(request.longitude, request.latitude),
        ),
        zoom: 14.5,
        pitch: 45.0,
        bearing: 0.0,
        padding: MbxEdgeInsets(
          top: 140,
          left: 60,
          right: 60,
          bottom: 260,
        ),
      ),
      MapAnimationOptions(duration: 900, startDelay: 0),
    );

    startNavigationTracking(request);
  } catch (e) {
    debugPrint('startDirections error: $e');

    await _navigationPositionSub?.cancel();
    ref.read(activeNavigationProvider.notifier).state = null;
    _navigationPositionSub = null;

if (!mounted) return;
setState(() {
  activeNavigationRequest = null;
  ref.read(activeNavigationProvider.notifier).state = request;
  isNavigationUiOpen = false;
});
_notifyNavigationIconVisibility();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to load route right now.'),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        isFetchingRoute = false;
      });
    }
  }
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
    setState(() {
      activeDirectionsRequest = null;
    });
  }

  Future<void> stopNavigation() async {
  await _navigationPositionSub?.cancel();
  _navigationPositionSub = null;
  _lastReroutePosition = null;
  _isRerouting = false;

  await clearRouteLine();

  if (!mounted) return;
  setState(() {
    activeNavigationRequest = null;
    isNavigationUiOpen = false;
    activeDirectionsRequest = null;
    ref.read(activeNavigationProvider.notifier).state = null;
  });
  _notifyNavigationIconVisibility();
  centerOnUserPuck();
}

  void handleEventTap(int eventId) {
    final callback = widget.onEventSelected;
    if (callback != null) {
      callback(eventId);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    pinsRefreshTimer?.cancel();
    settingsSubscription?.close();
    pendingDirectionsSubscription?.close();
    _navigationPositionSub?.cancel();
    pointAnnotationManager?.deleteAll();
    _headingPositionSub?.cancel();
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
            onCameraChangeListener: onCameraChange,
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
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
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
                onStartDirections: () =>
                    startDirections(activeDirectionsRequest!),
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
                  setState(() {
                    isNavigationUiOpen = false;
                  });
                },
              ),
            ),
          ),
      ],
    );
  }
}

class DirectionsActionCard extends StatelessWidget {
  final String title;
  final bool isLoading;
  final VoidCallback onStartDirections;
  final VoidCallback onReturnToEventDetails;
  final VoidCallback onClose;

  const DirectionsActionCard({
    super.key,
    required this.title,
    required this.onStartDirections,
    required this.onReturnToEventDetails,
    required this.onClose,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outline),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow,
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.navigation_rounded, color: colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: Icon(
                      Icons.close,
                      color: colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : onStartDirections,
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Start directions',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: onReturnToEventDetails,
                  child: const Text(
                    'Return to event details',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActiveNavigationCard extends StatelessWidget {
  final String title;
  final VoidCallback onStopNavigation;
  final VoidCallback onViewEventDetails;
  final VoidCallback onClose;

  const ActiveNavigationCard({
    super.key,
    required this.title,
    required this.onStopNavigation,
    required this.onViewEventDetails,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outline),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow,
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.navigation_rounded, color: colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: Icon(
                      Icons.close,
                      color: colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: onStopNavigation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Stop navigation',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: onViewEventDetails,
                  child: const Text(
                    'View event details',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MapPinClickListener extends OnPointAnnotationClickListener {
  final void Function(PointAnnotation annotation) onTap;

  MapPinClickListener({
    required this.onTap,
  });

  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    onTap(annotation);
  }
}