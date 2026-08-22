import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../../core/utils/logger.dart';
import '../../../../shared/events/models/event_map_pin_data.dart';

class _PinClickListener
    extends OnPointAnnotationClickListener {
  _PinClickListener({
    required this.onTap,
  });

  final void Function(PointAnnotation annotation) onTap;

  @override
  void onPointAnnotationClick(
    PointAnnotation annotation,
  ) {
    onTap(annotation);
  }
}

class MapPinAnnotationService {
  PointAnnotationManager? _manager;
  _PinClickListener? _clickListener;

  final Map<String, int> _annotationEventIds =
      <String, int>{};

  Future<void> prepare({
    required MapboxMap mapboxMap,
    required void Function(int eventId) onEventTap,
  }) async {
    if (_manager != null) {
      return;
    }

    _manager = await mapboxMap.annotations
        .createPointAnnotationManager();

    await _manager!.setIconAllowOverlap(true);
    await _manager!.setTextAllowOverlap(true);
    await _manager!.setIconIgnorePlacement(true);
    await _manager!.setTextIgnorePlacement(true);

    _clickListener = _PinClickListener(
      onTap: (annotation) {
        final eventId =
            _annotationEventIds[annotation.id];

        if (eventId != null) {
          onEventTap(eventId);
        }
      },
    );

    _manager!.addOnPointAnnotationClickListener(
      _clickListener!,
    );
  }

  Future<void> clear() async {
    await _manager?.deleteAll();
    _annotationEventIds.clear();
  }

  Future<void> syncPins({
    required List<EventMapPinData> events,
  }) async {
    final manager = _manager;

    if (manager == null) {
      AppLogger.warning(
        'Annotation manager is not ready.',
        tag: 'MapPinAnnotationService',
      );
      return;
    }

    await clear();

    if (events.isEmpty) {
      AppLogger.info(
        'No events available for map pins.',
        tag: 'MapPinAnnotationService',
      );
      return;
    }

    AppLogger.info(
      'Backend pin scores: ${events.map(
        (event) =>
            '${event.id}:${event.recommendationScore}',
      ).join(', ')}',
      tag: 'MapPinAnnotationService',
    );

    final options = <PointAnnotationOptions>[];
    final eventIds = <int>[];

    for (final event in events) {
      final imageBytes =
          await _buildCircularEventImage(
        imageUrl: event.imageUrl,
        borderColor: event.categoryColor,
        title: event.title,
      );

      if (imageBytes == null ||
          imageBytes.isEmpty) {
        AppLogger.warning(
          'Could not build pin image for '
          'event ${event.id}.',
          tag: 'MapPinAnnotationService',
        );
        continue;
      }

      options.add(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(
              event.lng,
              event.lat,
            ),
          ),
          image: imageBytes,
          iconAnchor: IconAnchor.CENTER,
          iconOffset: [0.0, -0.55],
          iconSize: _iconSizeForScore(
            event.recommendationScore,
          ),
          iconOpacity: 1.0,
        ),
      );

      eventIds.add(event.id);
    }

    if (options.isEmpty) {
      AppLogger.warning(
        'No pin options were created.',
        tag: 'MapPinAnnotationService',
      );
      return;
    }

    try {
      final annotations =
          await manager.createMulti(options);

      for (var index = 0;
          index < annotations.length;
          index++) {
        final annotation = annotations[index];

        if (annotation == null ||
            index >= eventIds.length) {
          continue;
        }

        _annotationEventIds[annotation.id] =
            eventIds[index];
      }

      AppLogger.info(
        'Created ${annotations.length} pins.',
        tag: 'MapPinAnnotationService',
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to create map pins.',
        tag: 'MapPinAnnotationService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  double _iconSizeForScore(int score) {
    const minScore = 0;
    const maxScore = 140;
    const minSize = 0.95;
    const maxSize = 1.75;

    final clampedScore = score.clamp(
      minScore,
      maxScore,
    );

    final ratio = clampedScore / maxScore;

    return minSize +
        ((maxSize - minSize) * ratio);
  }

  Future<Uint8List?> _buildCircularEventImage({
    required String? imageUrl,
    required Color borderColor,
    required String title,
  }) async {
    ui.Codec? sourceCodec;
    ui.Image? sourceImage;
    ui.Picture? picture;
    ui.Image? resultImage;

    try {
      final url = imageUrl?.trim() ?? '';

      final sourceBytes = url.isEmpty
          ? null
          : await _downloadImage(url);

      if (sourceBytes != null) {
        sourceCodec = await ui.instantiateImageCodec(
          sourceBytes,
        );

        final frame =
            await sourceCodec.getNextFrame();

        sourceImage = frame.image;
      }

      const imageSize = 128.0;
      const borderWidth = 14.0;
      const labelGap = 8.0;
      const labelHeight = 44.0;
      const canvasWidth = 300.0;
      const titleHorizontalPadding = 18.0;
      const maxTitleWidth = 230.0;

      final safeTitle = _shortenTitle(
        title.trim().isEmpty
            ? 'Event'
            : title,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final circleLeft =
          (canvasWidth - imageSize) / 2.0;

      final outerRect = Rect.fromLTWH(
        circleLeft,
        0,
        imageSize,
        imageSize,
      );

      final innerRect = Rect.fromLTWH(
        circleLeft + borderWidth,
        borderWidth,
        imageSize -
            borderWidth * 2.0,
        imageSize -
            borderWidth * 2.0,
      );

      final outerCircle = Path()
        ..addOval(outerRect);

      final innerCircle = Path()
        ..addOval(innerRect);

      canvas.drawPath(
        outerCircle,
        Paint()
          ..color = borderColor
          ..isAntiAlias = true,
      );

      if (sourceImage != null) {
        canvas.save();
        canvas.clipPath(innerCircle);

        canvas.drawImageRect(
          sourceImage,
          Rect.fromLTWH(
            0,
            0,
            sourceImage.width.toDouble(),
            sourceImage.height.toDouble(),
          ),
          innerRect,
          Paint()
            ..filterQuality =
                FilterQuality.high
            ..isAntiAlias = true,
        );

        canvas.restore();
      } else {
        canvas.drawPath(
          innerCircle,
          Paint()
            ..color = Colors.white
            ..isAntiAlias = true,
        );
      }

      final textPainter = TextPainter(
        text: TextSpan(
          text: safeTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24.0,
            fontWeight: FontWeight.w700,
            height: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 1,
        ellipsis: '…',
      );

      textPainter.layout(
        maxWidth: maxTitleWidth,
      );

      final labelWidth = math.min(
        maxTitleWidth +
            titleHorizontalPadding * 2.0,
        textPainter.width +
            titleHorizontalPadding * 2.0,
      );

      final labelLeft =
          (canvasWidth - labelWidth) / 2.0;

      final labelTop =
          imageSize + labelGap;

      final labelRect =
          RRect.fromRectAndRadius(
        Rect.fromLTWH(
          labelLeft,
          labelTop,
          labelWidth,
          labelHeight,
        ),
        const Radius.circular(11.0),
      );

      canvas.drawRRect(
        labelRect,
        Paint()
          ..color = Colors.black.withAlpha(175)
          ..isAntiAlias = true,
      );

      textPainter.paint(
        canvas,
        Offset(
          labelRect.left +
              (labelRect.width -
                      textPainter.width) /
                  2.0,
          labelRect.top +
              (labelRect.height -
                      textPainter.height) /
                  2.0,
        ),
      );

      picture = recorder.endRecording();

      final canvasHeight =
          imageSize + labelGap + labelHeight;

      resultImage = await picture.toImage(
        canvasWidth.ceil(),
        canvasHeight.ceil(),
      );

      final data = await resultImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      return data?.buffer.asUint8List();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to build event pin image.',
        tag: 'MapPinAnnotationService',
        error: error,
        stackTrace: stackTrace,
      );

      return null;
    } finally {
      resultImage?.dispose();
      picture?.dispose();
      sourceImage?.dispose();
      sourceCodec?.dispose();
    }
  }

  String _shortenTitle(String value) {
    const maxCharacters = 28;
    final trimmed = value.trim();

    if (trimmed.length <= maxCharacters) {
      return trimmed;
    }

    return '${trimmed.substring(
      0,
      maxCharacters - 1,
    )}…';
  }

  Future<Uint8List?> _downloadImage(
    String url,
  ) async {
    try {
      final response = await NetworkAssetBundle(
        Uri.parse(url),
      ).load(url);

      return response.buffer.asUint8List();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to download event image.',
        tag: 'MapPinAnnotationService',
        error: error,
        stackTrace: stackTrace,
      );

      return null;
    }
  }

  Future<void> dispose() async {
    await clear();
    _clickListener = null;
    _manager = null;
  }
}