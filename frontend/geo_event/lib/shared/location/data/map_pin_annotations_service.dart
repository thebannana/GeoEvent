import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../../shared/events/models/event_map_pin_data.dart';

class MapPinClickListener extends OnPointAnnotationClickListener {
  final void Function(PointAnnotation annotation) onTap;

  MapPinClickListener({required this.onTap});

  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    onTap(annotation);
  }
}

class MapPinAnnotationService {
  PointAnnotationManager? manager;
  final Map<String, int> annotationEventIds = {};

  Future<void> prepare({
    required MapboxMap mapboxMap,
    required void Function(int eventId) onEventTap,
  }) async {
    if (manager != null) return;

    manager = await mapboxMap.annotations.createPointAnnotationManager();
    await manager!.setIconAllowOverlap(true);
    await manager!.setTextAllowOverlap(true);
    await manager!.setIconIgnorePlacement(true);
    await manager!.setTextIgnorePlacement(true);

    manager!.addOnPointAnnotationClickListener(
      MapPinClickListener(
        onTap: (annotation) {
          final eventId = annotationEventIds[annotation.id];
          if (eventId != null) {
            onEventTap(eventId);
          }
        },
      ),
    );
  }

  Future<void> clear() async {
    await manager?.deleteAll();
    annotationEventIds.clear();
  }

  Future<void> syncPins({
    required List<EventMapPinData> events,
    required Future<Uint8List?> Function(String eventId) capturePinBytes,
  }) async {
    if (manager == null || events.isEmpty) return;

    await clear();

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

    final annotations = await manager!.createMulti(options);
    for (var i = 0; i < annotations.length; i++) {
      final annotationId = annotations[i]?.id;
      if (annotationId == null) continue;
      annotationEventIds[annotationId] = eventIdsForOptions[i];
    }
  }

  Future<void> dispose() async {
    await clear();
    manager = null;
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
          onError: (_, __) {},
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

      final markerContext = key.currentContext;
      if (markerContext == null) continue;

      final boundary = markerContext.findRenderObject() as RenderRepaintBoundary?;
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
}