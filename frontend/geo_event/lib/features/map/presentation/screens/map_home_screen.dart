import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../../core/config/app_env.dart';
import '../../application/map_settings_controller.dart';
import '../../../../shared/events/models/event_map_pin_data.dart';
import '../widgets/event_pin_marker.dart';
import '../widgets/map_filter_panel.dart';
import '../../../../shared/events/data/events_api.dart';

class MapHomeScreen extends ConsumerStatefulWidget {
  final ValueChanged<MapboxMap>? onMapReady;
  final ValueChanged<double>? onBearingChanged;
  final MapFilterSelection filterSelection;

  const MapHomeScreen({
    super.key,
    this.onMapReady,
    this.onBearingChanged,
    this.filterSelection = const MapFilterSelection(),
  });

  @override
  ConsumerState<MapHomeScreen> createState() => _MapHomeScreenState();
}

class _MapHomeScreenState extends ConsumerState<MapHomeScreen> {
  static const ui.Size _pinLogicalSize = ui.Size(190, 132);
  static const String _terrainSourceId = 'geoevent-terrain-source';

  static const double _baseZoom = 13.0;
  static const double _cityZoom = 15.5;
  static const double _cityPitch = 60.0;
  static const double _terrainExaggeration = 1.55;

  static const double _defaultLng = 18.4131;
  static const double _defaultLat = 43.8563;

  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;

  bool _styleLoaded = false;
  bool _eventPinsAdded = false;
  bool _captureReady = false;
  bool _terrainSourceAdded = false;
  bool _isLoadingMapPins = false;
  final double _currentLatitude = _defaultLat;
  final double _currentLongitude = _defaultLng;

  final Map<String, GlobalKey> _pinKeys = {};

  late List<EventMapPinData> _events;

  @override
  void initState() {
    super.initState();

    AppEnv.validate();
    MapboxOptions.setAccessToken(AppEnv.mapboxToken);

    _events = [];
    _rebuildPinKeys();
    _scheduleInitialLoad();
  }

  @override
  void didUpdateWidget(covariant MapHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.filterSelection != widget.filterSelection) {
      _reloadMapPins();
    }
  }

  void _rebuildPinKeys() {
    _pinKeys
      ..clear()
      ..addEntries(_events.map((event) => MapEntry(event.id, GlobalKey())));
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    widget.onMapReady?.call(mapboxMap);
    _hideBuiltInCompass();
    _prepareAnnotations();
    _tryAddEventPins();
  }

  Future<void> _hideBuiltInCompass() async {
    if (_mapboxMap == null) return;

    await _mapboxMap!.compass.updateSettings(
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

  Future<void> _prepareAnnotations() async {
    if (_mapboxMap == null || _pointAnnotationManager != null) return;

    _pointAnnotationManager =
        await _mapboxMap!.annotations.createPointAnnotationManager();

    await _pointAnnotationManager!.setIconAllowOverlap(true);
    await _pointAnnotationManager!.setTextAllowOverlap(true);
    await _pointAnnotationManager!.setIconIgnorePlacement(true);
    await _pointAnnotationManager!.setTextIgnorePlacement(true);
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData _) async {
    await _hideBuiltInCompass();
    await _prepareAnnotations();

    _terrainSourceAdded = false;

    if (!mounted) return;
    setState(() {
      _styleLoaded = true;
    });

    final settings = ref.read(mapSettingsControllerProvider);

    await _applyStandardMapConfiguration(settings);
    await _applyTerrain(settings.terrain);
    await _applyEventPinsVisibility(settings.eventPins);
  }

  void _onCameraChange(CameraChangedEventData event) {
    widget.onBearingChanged?.call(event.cameraState.bearing);
  }

void _scheduleInitialLoad() {
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (!mounted) return;

    setState(() {
      _captureReady = true;
      _isLoadingMapPins = true;
    });

    final pins = await _fetchMapPins();

    if (!mounted) return;

    setState(() {
      _events = pins;
      _isLoadingMapPins = false;
      _rebuildPinKeys();
    });

    // Give the hidden marker layer one frame to render before capturing
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await _tryAddEventPins();
    });
  });
}

  String _baseStyleUri() {
    return MapboxStyles.STANDARD;
  }

  String _resolveLightPreset() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 8) return 'dawn';
    if (hour >= 8 && hour < 18) return 'day';
    if (hour >= 18 && hour < 20) return 'dusk';
    return 'night';
  }

  Future<void> _applyStandardMapConfiguration(MapSettingsState settings) async {
    if (_mapboxMap == null || !_styleLoaded) return;

    try {
      await _mapboxMap!.style.setStyleImportConfigProperty(
        'basemap',
        'lightPreset',
        settings.dayNightCycle ? _resolveLightPreset() : 'day',
      );
    } catch (_) {}

    try {
      await _mapboxMap!.style.setStyleImportConfigProperty(
        'basemap',
        'showPointOfInterestLabels',
        settings.mapPins,
      );
    } catch (_) {}

    try {
      await _mapboxMap!.style.setStyleImportConfigProperty(
        'basemap',
        'showTransitLabels',
        settings.mapPins,
      );
    } catch (_) {}

    try {
      await _mapboxMap!.style.setStyleImportConfigProperty(
        'basemap',
        'showPlaceLabels',
        true,
      );
    } catch (_) {}

    try {
      await _mapboxMap!.style.setStyleImportConfigProperty(
        'basemap',
        'showRoadLabels',
        true,
      );
    } catch (_) {}

    try {
      await _mapboxMap!.style.setStyleImportConfigProperty(
        'basemap',
        'show3dObjects',
        settings.map3D,
      );
    } catch (_) {}
  }

  Future<void> _ensureTerrainSource() async {
    if (_mapboxMap == null || !_styleLoaded || _terrainSourceAdded) return;

    try {
      await _mapboxMap!.style.addSource(
        RasterDemSource(
          id: _terrainSourceId,
          url: 'mapbox://mapbox.mapbox-terrain-dem-v1',
          tileSize: 512,
          maxzoom: 14,
        ),
      );
    } catch (_) {}

    _terrainSourceAdded = true;
  }

  Future<void> _applyTerrain(bool enabled) async {
    if (_mapboxMap == null || !_styleLoaded) return;

    await _ensureTerrainSource();

    final exaggeration = enabled ? _terrainExaggeration : 0.0;

    try {
      await _mapboxMap!.style.setStyleTerrain(
        '''
        {
          "source": "$_terrainSourceId",
          "exaggeration": $exaggeration
        }
        ''',
      );
    } catch (_) {
      return;
    }

    try {
      await _mapboxMap!.style.setStyleTerrainProperty(
        'exaggeration',
        exaggeration,
      );
    } catch (_) {}
  }

  Future<void> _animateCameraFor3D(bool enabled) async {
    if (_mapboxMap == null) return;

    await _mapboxMap!.easeTo(
      CameraOptions(
        zoom: enabled ? _cityZoom : _baseZoom,
        pitch: enabled ? _cityPitch : 0.0,
      ),
      MapAnimationOptions(
        duration: 550,
        startDelay: 0,
      ),
    );
  }

  Future<void> _applyEventPinsVisibility(bool visible) async {
    if (_pointAnnotationManager == null) return;

    await _pointAnnotationManager!.deleteAll();
    _eventPinsAdded = false;

    if (visible) {
      await _tryAddEventPins();
    }

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _reloadMapPins() async {
    if (_pointAnnotationManager == null) return;

    setState(() {
      _isLoadingMapPins = true;
      _eventPinsAdded = false;
    });

    await _pointAnnotationManager!.deleteAll();

    final pins = await _fetchMapPins();

    if (!mounted) return;

    setState(() {
      _events = pins;
      _rebuildPinKeys();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await _tryAddEventPins();
    });
  }

Future<List<EventMapPinData>> _fetchMapPins() async {
  try {
    final items = await ref.read(eventsApiProvider).getNearbyEvents(
      latitude: _currentLatitude,
      longitude: _currentLongitude,
      radiusKm: widget.filterSelection.radiusKm,
      limit: 100,
      segmentId: widget.filterSelection.segmentId,
      genreId: widget.filterSelection.genreId,
      subGenreId: widget.filterSelection.subGenreId,
      minPrice: widget.filterSelection.minPrice,
      maxPrice: widget.filterSelection.maxPrice,
      freeOnly: widget.filterSelection.freeOnly,
      todayOnly: widget.filterSelection.todayOnly,
    );

    return items
        .map((e) => EventMapPinData(
              id: e.eventId.toString(),
              title: e.title,
              imageUrl: e.coverImageUrl,
              lng: e.longitude.toDouble(),
              lat: e.latitude.toDouble(),
            ))
        .toList();
  } catch (e) {
    debugPrint('_fetchMapPins error: $e');
    return [];
  }
}

  Future<void> _tryAddEventPins() async {
  final settings = ref.read(mapSettingsControllerProvider);

  debugPrint('tryAddPins: events=${_events.length}, style=$_styleLoaded, '
      'capture=$_captureReady, added=$_eventPinsAdded, manager=${_pointAnnotationManager != null}, '
      'visible=${settings.eventPins}');

  if (!settings.eventPins) return;
  if (!_styleLoaded || !_captureReady || _eventPinsAdded) return;
  if (_pointAnnotationManager == null) return;

  final options = <PointAnnotationOptions>[];

  for (final event in _events) {
    final bytes = await _capturePinBytes(event.id);
    debugPrint('capture ${event.id}: ${bytes?.lengthInBytes ?? 0} bytes');
    if (bytes == null) continue;

    options.add(
      PointAnnotationOptions(
        geometry: Point(
          coordinates: Position(event.lng, event.lat),
        ),
        image: bytes,
        iconAnchor: IconAnchor.BOTTOM,
        iconOffset: [0.0, -6.0],
      ),
    );
  }

  debugPrint('options ready: ${options.length}');

  if (options.isEmpty) return;

  try {
    await _pointAnnotationManager!.createMulti(options);
    debugPrint('createMulti success');
  } catch (e) {
    debugPrint('createMulti failed: $e');
    return;
  }

  if (!mounted) return;
  setState(() {
    _eventPinsAdded = true;
  });
}

  Future<Uint8List?> _capturePinBytes(String eventId) async {
  final key = _pinKeys[eventId];

  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 16));

    final markerContext = key?.currentContext;
    final boundary = markerContext?.findRenderObject() as RenderRepaintBoundary?;

    if (boundary != null && boundary.debugNeedsPaint == false) {
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return byteData?.buffer.asUint8List();
    }
  }

  debugPrint('Pin capture failed for eventId=$eventId');
  return null;
}

  Widget _buildHiddenMarkerLayer() {
  return Positioned(
    left: -10000,
    top: 0,
    child: IgnorePointer(
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _events.map((event) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RepaintBoundary(
                key: _pinKeys[event.id],
                child: EventPinMarker(
                  title: event.title,
                  imageUrl: event.imageUrl ?? '',
                  color: event.categoryColor,
                  width: _pinLogicalSize.width,
                  height: _pinLogicalSize.height,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    ),
  );
}

  @override
  void dispose() {
    _pointAnnotationManager?.deleteAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<MapSettingsState>(
      mapSettingsControllerProvider,
      (previous, next) async {
        if (previous == null) return;

        if (previous.map3D != next.map3D) {
          await _applyStandardMapConfiguration(next);
          await _animateCameraFor3D(next.map3D);
        }

        if (previous.terrain != next.terrain) {
          await _applyTerrain(next.terrain);
        }

        if (previous.dayNightCycle != next.dayNightCycle) {
          await _applyStandardMapConfiguration(next);
        }

        if (previous.mapPins != next.mapPins) {
          await _applyStandardMapConfiguration(next);
        }

        if (previous.eventPins != next.eventPins) {
          await _applyEventPinsVisibility(next.eventPins);
        }
      },
    );

    final settings = ref.watch(mapSettingsControllerProvider);

    return Stack(
      children: [
        Positioned.fill(
          child: MapWidget(
            key: const ValueKey('geo-event-map'),
            textureView: true,
            styleUri: _baseStyleUri(),
            cameraOptions: CameraOptions(
              center: Point(
                coordinates: Position(_defaultLng, _defaultLat),
              ),
              zoom: settings.map3D ? _cityZoom : _baseZoom,
              bearing: 0.0,
              pitch: settings.map3D ? _cityPitch : 0.0,
            ),
            onMapCreated: _onMapCreated,
            onStyleLoadedListener: _onStyleLoaded,
            onCameraChangeListener: _onCameraChange,
          ),
        ),
        _buildHiddenMarkerLayer(),
        if (!_styleLoaded || _isLoadingMapPins)
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
      ],
    );
  }
}