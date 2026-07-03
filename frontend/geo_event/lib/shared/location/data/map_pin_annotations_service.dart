import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../../shared/events/models/event_map_pin_data.dart';

class _PinClickListener extends OnPointAnnotationClickListener {
  final void Function(PointAnnotation annotation) onTap;

  _PinClickListener({required this.onTap});

  @override
  void onPointAnnotationClick(PointAnnotation annotation) => onTap(annotation);
}

class MapPinAnnotationService {
  PointAnnotationManager? _manager;
  _PinClickListener? _clickListener;
  final Map<String, int> _annotationEventIds = {};

  Future<void> prepare({
    required MapboxMap mapboxMap,
    required void Function(int eventId) onEventTap,
  }) async {
    if (_manager != null) return;

    _manager = await mapboxMap.annotations.createPointAnnotationManager();
    await _manager!.setIconAllowOverlap(true);
    await _manager!.setTextAllowOverlap(true);
    await _manager!.setIconIgnorePlacement(true);
    await _manager!.setTextIgnorePlacement(true);

    _clickListener = _PinClickListener(
      onTap: (annotation) {
        final eventId = _annotationEventIds[annotation.id];
        if (eventId != null) {
          onEventTap(eventId);
        }
      },
    );

    _manager!.addOnPointAnnotationClickListener(_clickListener!);
  }

  Future<void> clear() async {
    await _manager?.deleteAll();
    _annotationEventIds.clear();
  }

  Future<void> syncPins({
    required List<EventMapPinData> events,
    required Future<Uint8List?> Function(int eventId) capturePinBytes,
  }) async {
    if (_manager == null) return;

    await clear();

    if (events.isEmpty) return;

    final eventIdsForOptions = <int>[];
    final options = <PointAnnotationOptions>[];

    for (final event in events) {
      final bytes = await capturePinBytes(event.id);
      if (bytes == null) continue;

      options.add(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(event.lng, event.lat)),
          image: bytes,
          iconAnchor: IconAnchor.BOTTOM,
          iconOffset: [0.0, -6.0],
        ),
      );
      eventIdsForOptions.add(event.id);
    }

    if (options.isEmpty) return;

    final annotations = await _manager!.createMulti(options);
    for (var i = 0; i < annotations.length; i++) {
      final annotationId = annotations[i]?.id;
      if (annotationId == null) continue;
      _annotationEventIds[annotationId] = eventIdsForOptions[i];
    }
  }

  Future<void> precacheMarkerImages(
    BuildContext context,
    List<EventMapPinData> events,
  ) async {
    for (final event in events) {
      final url = (event.imageUrl ?? '').trim();
      if (url.isEmpty) continue;

      try {
        await precacheImage(
          NetworkImage(url),
          context,
          onError: (_, _) {},
        );
      } catch (_) {}
    }
  }

  Future<Uint8List?> capturePinBytes({
    required GlobalKey key,
    double pixelRatio = 3.0,
  }) async {
    for (var i = 0; i < 30; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 32));

      final ctx = key.currentContext;
      if (ctx == null) continue;

      final boundary = ctx.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null || boundary.debugNeedsPaint) continue;

      try {
        final image = await boundary.toImage(pixelRatio: pixelRatio);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();

        final bytes = byteData?.buffer.asUint8List();
        if (bytes != null && bytes.isNotEmpty) {
          return bytes;
        }
      } catch (_) {}
    }

    return null;
  }

  Future<void> dispose() async {
    await clear();
    _clickListener = null;
    _manager = null;
  }
}