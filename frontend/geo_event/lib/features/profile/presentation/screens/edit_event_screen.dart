import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/config/app_env.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_spinner.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../../../core/widgets/glass_scaffold.dart';
import '../../../../shared/events/models/create_event_models.dart';
import '../../../../shared/events/models/create_event_state.dart';
import '../../../../shared/events/models/my_event_response_dto.dart';
import '../../../../shared/location/providers/location_providers.dart';
import '../../../create_event/application/create_event_controller.dart';
import '../../../create_event/presentation/widgets/create_event_form.dart';
import '../../../create_event/presentation/widgets/create_event_image_picker.dart';
import '../../../create_event/presentation/widgets/create_event_location_picker.dart';
import '../../../create_event/presentation/widgets/create_event_taxonomy_section.dart';

class EditEventScreen extends ConsumerStatefulWidget {
  final MyEventResponseDto event;

  const EditEventScreen({
    super.key,
    required this.event,
  });

  @override
  ConsumerState<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends ConsumerState<EditEventScreen> {
  final titleCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final capacityCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final tagsCtrl = TextEditingController();
  final accessibilityCtrl = TextEditingController();
  final promoterCtrl = TextEditingController();
  final imagePicker = ImagePicker();

  static const int maxImageBytes = 10 * 1000 * 1000;
  static const allowedImageExtensions = ['.jpg', '.jpeg', '.png', '.webp'];

  DateTime? startAt;
  DateTime? endAt;

  @override
  void initState() {
    super.initState();

    final e = widget.event;
    titleCtrl.text = e.title;
    descriptionCtrl.text = e.description;
    capacityCtrl.text = e.capacity.toString();
    priceCtrl.text = _formatPrice(e.price);
    tagsCtrl.text = e.tags ?? '';
    accessibilityCtrl.text = e.accessibilityInfo ?? '';
    promoterCtrl.text = e.promoterName ?? '';
    startAt = e.startDateTime;
    endAt = e.endDateTime;

    Future.microtask(() async {
      final controller = ref.read(createEventControllerProvider.notifier);

      await controller.loadInitial();
      controller.hydrateForEdit(widget.event);

      if (widget.event.segmentId != null) {
        await controller.selectSegment(widget.event.segmentId);
      }
      if (widget.event.genreId != null) {
        await controller.selectGenre(widget.event.genreId);
      }
      if (widget.event.subGenreId != null) {
        controller.selectSubGenre(widget.event.subGenreId);
      }

      final needsResolvedLocation = widget.event.venueName == null ||
          widget.event.venueName!.trim().isEmpty;

      if (needsResolvedLocation) {
        try {
          final place =
              await ref.read(mapboxReverseGeocodingApiProvider).reverseGeocode(
                    latitude: widget.event.latitude,
                    longitude: widget.event.longitude,
                  );

          if (place != null && mounted) {
            controller.setSelectedLocation(place);
          }
        } catch (_) {
          // Keep fallback location from hydrateForEdit.
        }
      }
    });
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    descriptionCtrl.dispose();
    capacityCtrl.dispose();
    priceCtrl.dispose();
    tagsCtrl.dispose();
    accessibilityCtrl.dispose();
    promoterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createEventControllerProvider);
    final controller = ref.read(createEventControllerProvider.notifier);
    final theme = Theme.of(context);
    final isPublished = widget.event.status.trim().toLowerCase() == 'published';

    ref.listen<CreateEventState>(createEventControllerProvider, (prev, next) {
      final hadNoSuccess =
          prev?.successMessage == null || prev!.successMessage!.trim().isEmpty;
      final hasSuccess =
          next.successMessage != null && next.successMessage!.trim().isNotEmpty;

      if (hadNoSuccess && hasSuccess && mounted) {
        Navigator.of(context).pop(true);
      }
    });

    if (state.isFree && priceCtrl.text != '0') {
      priceCtrl.text = '0';
    }

    return GlassScaffold(
      appBar: AppBar(
        title: const Text('Edit event'),
        backgroundColor: Colors.transparent,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        children: [
          const Text(
            'Edit event',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Update your event details and save changes.',
            style: TextStyle(
              fontSize: 13,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 16),
          if (state.loadingInitial) ...[
            const AppLoadingIndicator(
              title: 'Loading event details',
              message: 'Please wait while we prepare the form.',
              centered: false,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
          ],
          if (state.errorMessage != null &&
              state.errorMessage!.trim().isNotEmpty) ...[
            InlineBanner(
              message: state.errorMessage!,
              isError: true,
            ),
            const SizedBox(height: 12),
          ],
          if (state.successMessage != null &&
              state.successMessage!.trim().isNotEmpty) ...[
            InlineBanner(
              message: state.successMessage!,
              isError: false,
            ),
            const SizedBox(height: 12),
          ],
          CreateEventForm(
            state: state,
            titleCtrl: titleCtrl,
            descriptionCtrl: descriptionCtrl,
            capacityCtrl: capacityCtrl,
            priceCtrl: priceCtrl,
            tagsCtrl: tagsCtrl,
            accessibilityCtrl: accessibilityCtrl,
            promoterCtrl: promoterCtrl,
            startAt: startAt,
            endAt: endAt,
            formatDateTime: formatDateTime,
            onPickStartDate: () async {
              final picked = await pickDateTime(context, initial: startAt);
              if (picked != null && mounted) {
                setState(() => startAt = picked);
              }
            },
            onPickEndDate: () async {
              final picked = await pickDateTime(
                context,
                initial: endAt ?? startAt,
              );
              if (picked != null && mounted) {
                setState(() => endAt = picked);
              }
            },
            onFreeChanged: (value) {
              controller.setFree(value);
              if (value) {
                priceCtrl.text = '0';
              }
            },
          ),
          const SizedBox(height: 12),
          if ((widget.event.coverImageUrl?.trim().isNotEmpty ?? false) ||
              widget.event.imageUrls.any((e) => e.trim().isNotEmpty)) ...[
            _ExistingImagesSection(event: widget.event),
            const SizedBox(height: 12),
          ],
          CreateEventImagePicker(
            state: state,
            onPickFeaturedImage: () => pickFeaturedImage(controller),
            onPickGalleryImages: () => pickGalleryImages(controller, state),
            onClearFeaturedImage: controller.clearFeaturedImage,
            onRemoveGalleryImageAt: controller.removeGalleryImageAt,
          ),
          const SizedBox(height: 12),
          CreateEventTaxonomySection(
            state: state,
            onSegmentChanged: controller.selectSegment,
            onGenreChanged: controller.selectGenre,
            onSubGenreChanged: controller.selectSubGenre,
          ),
          const SizedBox(height: 12),
          CreateEventLocationPicker(
            state: state,
            onTapPickLocation: () async {
              try {
                AppEnv.validate();
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'MAPBOX_ACCESS_TOKEN is missing. Run the app with --dart-define=MAPBOX_ACCESS_TOKEN=yourtoken',
                    ),
                  ),
                );
                return;
              }

              final picked = await showModalBottomSheet<MapboxPlace>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const LocationSearchSheet(),
              );

              if (picked != null) {
                controller.setSelectedLocation(picked);
              }
            },
            onClearLocation: controller.clearSelectedLocation,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: state.submitting
                      ? null
                      : () => submit(state, controller, publish: false),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: state.submitting
                        ? const AppSpinner(size: 18, strokeWidth: 2)
                        : Text(isPublished ? 'Save changes' : 'Save draft'),
                  ),
                ),
              ),
              if (!isPublished) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: state.submitting
                        ? null
                        : () => submit(state, controller, publish: true),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      child: state.submitting
                          ? const AppSpinner(
                              size: 18,
                              strokeWidth: 2,
                              color: Colors.white,
                            )
                          : const Text('Publish changes'),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> pickFeaturedImage(CreateEventController controller) async {
    final file = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (file == null) return;

    final validationError = await validatePickedImageWithSize(file);
    if (validationError != null) {
      controller.setFormError(validationError);
      return;
    }

    final bytes = kIsWeb ? await file.readAsBytes() : null;
    controller.setFeaturedImage(
      EventImageUploadItem(
        localPath: file.path,
        isCover: true,
        previewBytes: bytes,
      ),
    );
  }

  Future<void> pickGalleryImages(
    CreateEventController controller,
    CreateEventState state,
  ) async {
    final files = await imagePicker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;

    final existingPaths = <String>{
      if (state.featuredImage != null) state.featuredImage!.localPath,
      ...state.galleryImages.map((e) => e.localPath),
    };

    final newItems = <EventImageUploadItem>[];

    for (final file in files) {
      if (existingPaths.contains(file.path)) continue;

      final validationError = await validatePickedImageWithSize(file);
      if (validationError != null) {
        controller.setFormError(validationError);
        continue;
      }

      newItems.add(
        EventImageUploadItem(
          localPath: file.path,
          isCover: false,
          previewBytes: kIsWeb ? await file.readAsBytes() : null,
        ),
      );
    }

    if (newItems.isEmpty) return;
    controller.addGalleryImages(newItems);
  }

  Future<void> submit(
    CreateEventState state,
    CreateEventController controller, {
    required bool publish,
  }) async {
    final title = titleCtrl.text.trim();
    final description = descriptionCtrl.text.trim();
    final capacity = int.tryParse(capacityCtrl.text.trim());
    final price = state.isFree ? 0.0 : double.tryParse(priceCtrl.text.trim());
    final selectedLocation = state.selectedLocation;

    final normalizedStatus = widget.event.status.trim().toLowerCase();
    final isPublished =
        normalizedStatus == 'published' || normalizedStatus == 'active';
    final shouldPublish = !isPublished && publish;

    if (title.length < 3 || title.length > 200) {
      controller.setFormError('Title must be between 3 and 200 characters.');
      return;
    }

    if (description.length < 10 || description.length > 5000) {
      controller.setFormError(
        'Description must be between 10 and 5000 characters.',
      );
      return;
    }

    if (capacity == null || capacity < 0 || capacity > 1000000) {
      controller.setFormError('Capacity must be between 0 and 1,000,000.');
      return;
    }

    if (price == null || price < 0 || price > 100000) {
      controller.setFormError('Price must be between 0 and 100000.');
      return;
    }

    if (startAt == null || endAt == null) {
      controller.setFormError('Please select both start and end date.');
      return;
    }

    if (!endAt!.isAfter(startAt!)) {
      controller.setFormError('End date must be after start date.');
      return;
    }

    if (selectedLocation == null) {
      controller.setFormError('Please choose a location.');
      return;
    }

    await controller.submit(
      title: title,
      description: description,
      segmentId: state.segmentId,
      genreId: state.genreId,
      subGenreId: state.subGenreId,
      venueId: widget.event.venueId,
      cityId: widget.event.cityId,
      latitude: selectedLocation.latitude,
      longitude: selectedLocation.longitude,
      startDateTime: startAt!,
      endDateTime: endAt!,
      capacity: capacity,
      price: price,
      isOnline: false,
      tags: nullableString(tagsCtrl.text),
      externalUrl: null,
      accessibilityInfo: nullableString(accessibilityCtrl.text),
      promoterName: nullableString(promoterCtrl.text),
      locale: widget.event.locale,
      publish: shouldPublish,
    );
  }

  Future<DateTime?> pickDateTime(
    BuildContext context, {
    DateTime? initial,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final seed = initial ?? now.add(const Duration(hours: 1));
    final safeInitialDate = seed.isBefore(today) ? today : seed;

    final date = await showDatePicker(
      context: context,
      initialDate: safeInitialDate,
      firstDate: today,
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (date == null || !context.mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(seed),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<int?> readImageSize(XFile file) async {
    try {
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        return bytes.length;
      }
      return await File(file.path).length();
    } catch (_) {
      return null;
    }
  }

  Future<String?> validatePickedImageWithSize(XFile file) async {
    final typeError = validatePickedImage(file);
    if (typeError != null) return typeError;

    final size = await readImageSize(file);
    if (size == null) return 'Could not read the selected image.';
    if (size > maxImageBytes) return 'Image must be smaller than 10 MB.';
    return null;
  }

  String? validatePickedImage(XFile file) {
    final path = file.path.toLowerCase();
    final hasAllowedExtension = allowedImageExtensions.any(path.endsWith);
    if (!hasAllowedExtension) {
      return 'Only JPG, PNG, and WEBP images are allowed.';
    }
    return null;
  }

  static String formatDateTime(DateTime value) {
    final local = value.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final yyyy = local.year.toString();
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dd.$mm.$yyyy $hh:$min';
  }

  static String? nullableString(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _formatPrice(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
  }
}

class _ExistingImagesSection extends StatelessWidget {
  final MyEventResponseDto event;

  const _ExistingImagesSection({
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    final cover = event.coverImageUrl?.trim();
    final gallery = event.imageUrls
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if ((cover == null || cover.isEmpty) && gallery.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Existing images',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'These are the images already attached to this event. Picking new images will add more uploads for this edit flow.',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          if (cover != null && cover.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Cover image',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _RemoteEventImage(url: cover, height: 180),
          ],
          if (gallery.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Gallery',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: gallery.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  return _RemoteEventImage(
                    url: gallery[index],
                    width: 92,
                    height: 92,
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

class _RemoteEventImage extends StatelessWidget {
  final String url;
  final double? width;
  final double height;

  const _RemoteEventImage({
    required this.url,
    this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: width,
            height: height,
            color: theme.colorScheme.surfaceContainerHighest,
            alignment: Alignment.center,
            child: const AppSpinner(size: 22, strokeWidth: 2),
          );
        },
        errorBuilder: (_, __, ___) => Container(
          width: width,
          height: height,
          color: theme.colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Icon(
            Icons.broken_image_outlined,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}