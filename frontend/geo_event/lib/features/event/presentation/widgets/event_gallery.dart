import 'package:flutter/material.dart';

import '../../../../core/utils/logger.dart';

class EventGallery extends StatefulWidget {
  final List<String> imageUrls;

  const EventGallery({
    super.key,
    required this.imageUrls,
  });

  @override
  State<EventGallery> createState() => _EventGalleryState();
}

class _EventGalleryState extends State<EventGallery> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (widget.imageUrls.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Center(
          child: Icon(
            Icons.image_outlined,
            color: scheme.onSurface.withValues(alpha: 0.54),
            size: 42,
          ),
        ),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.imageUrls.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) {
                final imageUrl = widget.imageUrls[index];

                return Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stackTrace) {
                    AppLogger.warning(
                      'Failed to load gallery image: $imageUrl',
                      tag: 'EventGallery',
                    );

                    return Container(
                      color: scheme.surfaceContainerHighest,
                      child: Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: scheme.onSurface.withValues(alpha: 0.54),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        if (widget.imageUrls.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.imageUrls.length, (i) {
              final active = i == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: active
                      ? scheme.primary
                      : scheme.onSurface.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}