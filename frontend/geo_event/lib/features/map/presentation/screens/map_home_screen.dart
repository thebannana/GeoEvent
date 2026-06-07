import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../../core/config/app_env.dart';
import '../../../../shared/events/models/event_map_pin_data.dart';
import '../../../../shared/events/providers/event_providers.dart';
import '../../../../shared/location/models/event_directions_request.dart';
import '../../../../shared/location/providers/directions_providers.dart';
import '../../../event/presentation/screens/event_detail_screen.dart';
import '../../application/map_settings_controller.dart';
import '../widgets/event_pin_marker.dart';
import '../widgets/map_filter_panel.dart';

class MapHomeScreen extends ConsumerStatefulWidget {
  final ValueChanged<MapboxMap>? onMapReady;
  final ValueChanged<double>? onBearingChanged;
  final ValueChanged<int>? onEventSelected;
  final MapFilterSelection filterSelection;

  const MapHomeScreen({
    super.key,
    this.onMapReady,
    this.onBearingChanged,
    this.onEventSelected,
    this.filterSelection = const MapFilterSelection(),
  });

  @override
  ConsumerState<MapHomeScreen> createState() => MapHomeScreenState();
}

class MapHomeScreenState extends ConsumerState<MapHomeScreen>
    with WidgetsBindingObserver {
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
  ProviderSubscription<MapSettingsState>? _settingsSubscription;
  ProviderSubscription<EventDirectionsRequest?>? _pendingDirectionsSubscription;
  Timer? _pinsRefreshTimer;

  bool _styleLoaded = false;
  bool _captureReady = false;
  bool _terrainSourceAdded = false;
  bool _isLoadingMapPins = false;
  bool _isSyncingPins = false;
  bool _handlingPendingDirections = false;
  bool _hasHandledInitialPendingDirections = false;

  final double _currentLatitude = _defaultLat;
  final double _currentLongitude = _defaultLng;

  final Map<String, GlobalKey> _pinKeys = {};
  final Map<String, int> _annotationEventIds = {};

  late List<EventMapPinData> _events;
  EventDirectionsRequest? _activeDirectionsRequest;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppEnv.validate();
    MapboxOptions.setAccessToken(AppEnv.mapboxToken);

    _events = [];
    _rebuildPinKeys();
    _listenToMapSettings();
    _listenToPendingDirections();
    _scheduleInitialLoad();
    _startPinsAutoRefresh();
  }

  @override
  void didUpdateWidget(covariant MapHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.filterSelection != widget.filterSelection) {
      _reloadMapPins();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reloadMapPins();
    }
  }

  void _startPinsAutoRefresh() {
    _pinsRefreshTimer?.cancel();
    _pinsRefreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _reloadMapPins(silent: true),
    );
  }

  void _listenToMapSettings() {
    _settingsSubscription?.close();
    _settingsSubscription = ref.listenManual<MapSettingsState>(
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
  }

  void _listenToPendingDirections() {
    _pendingDirectionsSubscription?.close();
    _pendingDirectionsSubscription =
        ref.listenManual<EventDirectionsRequest?>(
      pendingDirectionsProvider,
      (previous, next) async {
        if (next == null || _handlingPendingDirections) return;
        await _tryHandlePendingDirections(next);
      },
    );
  }

  bool get _isReadyForPendingDirections =>
      mounted && _mapboxMap != null && _styleLoaded && _captureReady;

  Future<void> _tryHandlePendingDirections(
    EventDirectionsRequest request,
  ) async {
    if (!_isReadyForPendingDirections) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!_isReadyForPendingDirections || !mounted) return;
    }

    _handlingPendingDirections = true;
    try {
      await focusOnEventLocation(
        latitude: request.latitude,
        longitude: request.longitude,
      );

      if (!mounted) return;
      setState(() {
        _activeDirectionsRequest = request;
      });

      ref.read(pendingDirectionsProvider.notifier).state = null;
      _hasHandledInitialPendingDirections = true;
    } finally {
      _handlingPendingDirections = false;
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
    _consumeInitialPendingDirectionsIfNeeded();
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

    _pointAnnotationManager!.addOnPointAnnotationClickListener(
      _MapPinClickListener(
        onTap: (annotation) {
          final eventId = _annotationEventIds[annotation.id];
          if (eventId == null || !mounted) return;
          _handleEventTap(eventId);
        },
      ),
    );
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

    await _reloadMapPins(
      silent: true,
      forceResync: true,
    );

    await _consumeInitialPendingDirectionsIfNeeded();
  }

  void _onCameraChange(CameraChangedEventData event) {
    widget.onBearingChanged?.call(event.cameraState.bearing);
  }

  void _scheduleInitialLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      setState(() {
        _captureReady = true;
      });

      await _reloadMapPins();
      await _consumeInitialPendingDirectionsIfNeeded();
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

  Future<void> focusOnEventLocation({
    required double latitude,
    required double longitude,
  }) async {
    if (_mapboxMap == null) return;

    final settings = ref.read(mapSettingsControllerProvider);

    await _mapboxMap!.easeTo(
      CameraOptions(
        center: Point(coordinates: Position(longitude, latitude)),
        zoom: settings.map3D ? _cityZoom : 15.8,
        pitch: settings.map3D ? _cityPitch : 0.0,
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

  Future<void> _consumeInitialPendingDirectionsIfNeeded() async {
    if (_hasHandledInitialPendingDirections) return;

    final request = ref.read(pendingDirectionsProvider);
    if (request == null) {
      _hasHandledInitialPendingDirections = true;
      return;
    }

    await _tryHandlePendingDirections(request);
  }

  Future<void> _applyEventPinsVisibility(bool visible) async {
    if (_pointAnnotationManager == null) return;

    await _pointAnnotationManager!.deleteAll();
    _annotationEventIds.clear();

    if (visible) {
      await _tryAddEventPins();
    }

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _reloadMapPins({
    bool silent = false,
    bool forceResync = false,
  }) async {
    if (!mounted || _isSyncingPins) return;

    if (!silent) {
      setState(() {
        _isLoadingMapPins = true;
      });
    }

    final pins = await _fetchMapPins();
    if (!mounted) return;

    final oldSignature = _events
        .map((e) => '${e.id}:${e.lat}:${e.lng}:${e.imageUrl}')
        .join('|');
    final newSignature = pins
        .map((e) => '${e.id}:${e.lat}:${e.lng}:${e.imageUrl}')
        .join('|');

    final hasChanged = oldSignature != newSignature;

    if (!hasChanged && !forceResync) {
      if (!silent && mounted) {
        setState(() {
          _isLoadingMapPins = false;
        });
      }
      return;
    }

    setState(() {
      _events = pins;
      _rebuildPinKeys();
      if (!silent) {
        _isLoadingMapPins = false;
      }
    });

    await _precacheMarkerImages();
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 180));

    if (!mounted) return;
    await _syncEventPins();
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

      return items.map(EventMapPinData.fromEventItem).toList();
    } catch (e) {
      debugPrint('_fetchMapPins error: $e');
      return [];
    }
  }

  Future<void> _syncEventPins() async {
    if (_pointAnnotationManager == null) return;

    await _pointAnnotationManager!.deleteAll();
    _annotationEventIds.clear();

    await _tryAddEventPins();

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _tryAddEventPins() async {
    final settings = ref.read(mapSettingsControllerProvider);

    if (_isSyncingPins) return;
    if (!settings.eventPins) return;
    if (!_styleLoaded || !_captureReady) return;
    if (_pointAnnotationManager == null) return;
    if (_events.isEmpty) return;

    _isSyncingPins = true;

    try {
      final eventIdsForOptions = <int>[];
      final options = <PointAnnotationOptions>[];

      for (final event in _events) {
        final bytes = await _capturePinBytes(event.id);
        if (bytes == null) continue;

        final parsedEventId = int.tryParse(event.id);
        if (parsedEventId == null) continue;

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
        eventIdsForOptions.add(parsedEventId);
      }

      if (options.isEmpty) return;

      final annotations = await _pointAnnotationManager!.createMulti(options);

      for (var i = 0; i < annotations.length; i++) {
        final annotation = annotations[i];
        final annotationId = annotation?.id;
        if (annotationId == null) continue;

        _annotationEventIds[annotationId] = eventIdsForOptions[i];
      }

      if (!mounted) return;
    } catch (e) {
      debugPrint('_tryAddEventPins failed: $e');
    } finally {
      _isSyncingPins = false;
    }
  }

  Future<void> _precacheMarkerImages() async {
    for (final event in _events) {
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

  Future<Uint8List?> _capturePinBytes(String eventId) async {
    final key = _pinKeys[eventId];

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
        if (bytes != null && bytes.isNotEmpty) {
          return bytes;
        }
      } catch (_) {}
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

  Future<void> _startDirections(EventDirectionsRequest request) async {
    await focusOnEventLocation(
      latitude: request.latitude,
      longitude: request.longitude,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hook this button into your Mapbox route flow.'),
      ),
    );
  }

  void _returnToEventDetails(EventDirectionsRequest request) {
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventDetailsScreen(eventId: request.eventId),
      ),
    );
  }

  void _clearDirectionsCard() {
    if (!mounted) return;
    setState(() {
      _activeDirectionsRequest = null;
    });
  }

  void _handleEventTap(int eventId) {
    final callback = widget.onEventSelected;
    if (callback != null) {
      callback(eventId);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pinsRefreshTimer?.cancel();
    _settingsSubscription?.close();
    _pendingDirectionsSubscription?.close();
    _pointAnnotationManager?.deleteAll();
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
        if (_activeDirectionsRequest != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: SafeArea(
              top: false,
              child: _DirectionsActionCard(
                title: _activeDirectionsRequest!.title,
                onStartDirections: () =>
                    _startDirections(_activeDirectionsRequest!),
                onReturnToEventDetails: () =>
                    _returnToEventDetails(_activeDirectionsRequest!),
                onClose: _clearDirectionsCard,
              ),
            ),
          ),
      ],
    );
  }
}

class _DirectionsActionCard extends StatelessWidget {
  final String title;
  final VoidCallback onStartDirections;
  final VoidCallback onReturnToEventDetails;
  final VoidCallback onClose;

  const _DirectionsActionCard({
    required this.title,
    required this.onStartDirections,
    required this.onReturnToEventDetails,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF111317).withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.navigation_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onStartDirections,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82C4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
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
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Return to event details',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPinClickListener extends OnPointAnnotationClickListener {
  final void Function(PointAnnotation annotation) onTap;

  _MapPinClickListener({required this.onTap});

  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    onTap(annotation);
  }
}