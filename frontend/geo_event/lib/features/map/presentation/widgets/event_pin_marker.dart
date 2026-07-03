import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class EventPinMarker extends StatelessWidget {
  final String title;
  final String imageUrl;
  final Color color;
  final double width;
  final double height;

  const EventPinMarker({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.color,
    required this.width,
    required this.height,
  });

  static const double baseOuterCircleSize = 82;
  static const double baseInnerCircleSize = 64;
  static const double baseDiamondSize = 22;
  static const double baseImageBorderWidth = 2.4;
  static const double rotation45deg = 0.785398;

  static const double baseMarkerVisualSize = 96;
  static const double baseLabelGap = 6;
  static const double baseLabelHorizontalPadding = 14;
  static const double baseLabelVerticalPadding = 7;
  static const double baseLabelFontSize = 14;
  static const double baseLabelHeight = 30;

  static const double baseTotalWidth = 144;
  static const double baseTotalHeight =
      baseMarkerVisualSize + baseLabelGap + baseLabelHeight;

  String get safeTitle {
    final trimmed = title.trim();
    return trimmed.isEmpty ? 'Event' : trimmed;
  }

  bool get hasImage => imageUrl.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final targetWidth = width > 0 ? width : baseTotalWidth;
    final targetHeight = height > 0 ? height : baseTotalHeight;

    final scaleX = targetWidth / baseTotalWidth;
    final scaleY = targetHeight / baseTotalHeight;
    final scale = math.min(scaleX, scaleY);

    final actualWidth = baseTotalWidth * scale;
    final actualHeight = baseTotalHeight * scale;

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: targetWidth,
        height: targetHeight,
        child: Center(
          child: SizedBox(
            width: actualWidth,
            height: actualHeight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MarkerVisual(
                  color: color,
                  scale: scale,
                  image: hasImage ? buildCachedImage(scale) : buildFallback(scale),
                ),
                SizedBox(height: baseLabelGap * scale),
                MarkerLabel(
                  title: safeTitle,
                  scale: scale,
                  maxWidth: actualWidth,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildCachedImage(double scale) {
    final imageSize = baseInnerCircleSize * scale;

    return SizedBox(
      width: imageSize,
      height: imageSize,
      child: CachedNetworkImage(
        imageUrl: imageUrl.trim(),
        fit: BoxFit.cover,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholder: (_, _) => buildFallback(scale),
        errorWidget: (_, _, _) => buildFallback(scale),
      ),
    );
  }

  Widget buildFallback(double scale) {
    final imageSize = baseInnerCircleSize * scale;

    return SizedBox(
      width: imageSize,
      height: imageSize,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            Icons.event,
            color: const Color(0xFF222222),
            size: 26 * scale,
          ),
        ),
      ),
    );
  }
}

class MarkerVisual extends StatelessWidget {
  final Color color;
  final Widget image;
  final double scale;

  const MarkerVisual({
    super.key,
    required this.color,
    required this.image,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final visualSize = EventPinMarker.baseMarkerVisualSize * scale;
    final outerCircleSize = EventPinMarker.baseOuterCircleSize * scale;
    final innerCircleSize = EventPinMarker.baseInnerCircleSize * scale;
    final diamondSize = EventPinMarker.baseDiamondSize * scale;
    final imageBorderWidth = EventPinMarker.baseImageBorderWidth * scale;
    final diamondBottomOffset = 8 * scale;
    final diamondRadius = 4 * scale;

    return SizedBox(
      width: visualSize,
      height: visualSize,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: diamondBottomOffset,
            child: Transform.rotate(
              angle: EventPinMarker.rotation45deg,
              child: Container(
                width: diamondSize,
                height: diamondSize,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(diamondRadius),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x33000000),
                      blurRadius: 8 * scale,
                      offset: Offset(0, 3 * scale),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: Container(
              width: outerCircleSize,
              height: outerCircleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x33000000),
                    blurRadius: 12 * scale,
                    offset: Offset(0, 4 * scale),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: innerCircleSize,
                  height: innerCircleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: imageBorderWidth,
                    ),
                    color: Colors.white,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(imageBorderWidth),
                    child: ClipOval(
                      child: SizedBox.expand(child: image),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MarkerLabel extends StatelessWidget {
  final String title;
  final double maxWidth;
  final double scale;

  const MarkerLabel({
    super.key,
    required this.title,
    required this.maxWidth,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding =
        EventPinMarker.baseLabelHorizontalPadding * scale;
    final verticalPadding =
        EventPinMarker.baseLabelVerticalPadding * scale;
    final fontSize =
        math.max(10.5, EventPinMarker.baseLabelFontSize * scale);
    final height = EventPinMarker.baseLabelHeight * scale;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        minHeight: height,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xCC1C1C1E),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}