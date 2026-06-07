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

  static const double _outerCircleSize = 82;
  static const double _innerCircleSize = 64;
  static const double _diamondSize = 22;
  static const double _imageBorderWidth = 2.2;
  static const double _rotation45deg = 0.785398;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: width,
        height: height,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    bottom: 8,
                    child: Transform.rotate(
                      angle: _rotation45deg,
                      child: Container(
                        width: _diamondSize,
                        height: _diamondSize,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    child: Container(
                      width: _outerCircleSize,
                      height: _outerCircleSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: _innerCircleSize,
                          height: _innerCircleSize,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: _imageBorderWidth,
                            ),
                          ),
                          child: _buildImage(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Container(
              constraints: const BoxConstraints(maxWidth: 170),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xCC1C1C1E),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                title.trim().isEmpty ? 'Event' : title.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    final trimmed = imageUrl.trim();
    if (trimmed.isEmpty) {
      return _buildFallback();
    }

    return CachedNetworkImage(
      imageUrl: trimmed,
      fit: BoxFit.cover,
      width: _innerCircleSize,
      height: _innerCircleSize,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (_, __) => _buildFallback(),
      errorWidget: (_, __, ___) => _buildFallback(),
    );
  }

  Widget _buildFallback() {
    return Container(
      width: _innerCircleSize,
      height: _innerCircleSize,
      color: const Color(0xFFF5F5F5),
      alignment: Alignment.center,
      child: const Icon(
        Icons.event,
        color: Color(0xFF222222),
        size: 26,
      ),
    );
  }
}