import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../shared/events/models/create_event_models.dart';
import '../../../../shared/events/models/create_event_state.dart';
import 'create_event_form.dart';

class CreateEventImagePicker extends StatelessWidget {
  final CreateEventState state;
  final VoidCallback onPickFeaturedImage;
  final VoidCallback onPickGalleryImages;
  final VoidCallback onClearFeaturedImage;
  final ValueChanged<int> onRemoveGalleryImageAt;

  const CreateEventImagePicker({
    super.key,
    required this.state,
    required this.onPickFeaturedImage,
    required this.onPickGalleryImages,
    required this.onClearFeaturedImage,
    required this.onRemoveGalleryImageAt,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Images'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.submitting ? null : onPickFeaturedImage,
                  icon: const Icon(Icons.star_border_rounded),
                  label: Text(
                    state.featuredImage == null
                        ? 'Choose featured image'
                        : 'Replace featured image',
                  ),
                ),
              ),
            ],
          ),
          if (state.featuredImage != null) ...[
            const SizedBox(height: 12),
            ImagePreviewTile(
              item: state.featuredImage!,
              title: 'Featured image',
              subtitle: 'This will be used as the cover image.',
              onRemove: onClearFeaturedImage,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.submitting ? null : onPickGalleryImages,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Add gallery images'),
                ),
              ),
            ],
          ),
          if (state.galleryImages.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(
                state.galleryImages.length,
                (index) {
                  final image = state.galleryImages[index];
                  return GalleryImageCard(
                    item: image,
                    onRemove: () => onRemoveGalleryImageAt(index),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ImagePreviewTile extends StatelessWidget {
  final EventImageUploadItem item;
  final String title;
  final String subtitle;
  final VoidCallback onRemove;

  const ImagePreviewTile({
    super.key,
    required this.item,
    required this.title,
    required this.subtitle,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2A303A) : const Color(0xFFE3EAF3),
        ),
        color: isDark ? const Color(0xFF1B2028) : Colors.white,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: LocalImage(
              item: item,
              width: 72,
              height: 72,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class GalleryImageCard extends StatelessWidget {
  final EventImageUploadItem item;
  final VoidCallback onRemove;

  const GalleryImageCard({
    super.key,
    required this.item,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LocalImage(
              item: item,
              width: 96,
              height: 96,
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: onRemove,
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class LocalImage extends StatelessWidget {
  final EventImageUploadItem item;
  final double width;
  final double height;

  const LocalImage({
    super.key,
    required this.item,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && item.previewBytes != null) {
      return Image.memory(
        item.previewBytes!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => ImageFallback(
          width: width,
          height: height,
        ),
      );
    }

    if (!kIsWeb) {
      return Image.file(
        File(item.localPath),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => ImageFallback(
          width: width,
          height: height,
        ),
      );
    }

    return ImageFallback(
      width: width,
      height: height,
    );
  }
}

class ImageFallback extends StatelessWidget {
  final double width;
  final double height;

  const ImageFallback({
    super.key,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      color: isDark ? const Color(0xFF2A303A) : const Color(0xFFE9EEF5),
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported_outlined),
    );
  }
}