import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geo_event/core/config/app_environment.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/widgets/feedback/app_spinner.dart';
import '../../../../shared/events/models/create_event_models.dart';
import '../../../../shared/events/models/create_event_state.dart';
import '../../../../shared/events/providers/event_refresh_providers.dart';
import '../../application/create_event_controller.dart';
import '../widgets/create_event_form.dart';
import '../widgets/create_event_image_picker.dart';
import '../widgets/create_event_location_picker.dart';
import '../widgets/create_event_taxonomy_section.dart';

class CreateEventSuccessResult {
  const CreateEventSuccessResult({
    required this.eventId,
    required this.title,
    required this.latitude,
    required this.longitude,
    required this.published,
  });

  final int eventId;
  final String title;
  final double latitude;
  final double longitude;
  final bool published;
}

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({
    super.key,
    this.onCreated,
  });

  final Future<void> Function(CreateEventSuccessResult result)? onCreated;

  @override
  ConsumerState<CreateEventScreen> createState() => CreateEventScreenState();
}

class CreateEventScreenState extends ConsumerState<CreateEventScreen> {
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
    Future.microtask(
      () => ref.read(createEventControllerProvider.notifier).loadInitial(),
    );
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

    syncFreePrice(state);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      children: [
        const Text(
          'Create an event',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Fill in the details and publish your event.',
          style: TextStyle(
            fontSize: 13,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 16),
        if (state.loadingInitial) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 12),
        ],
        if (state.errorMessage != null && state.errorMessage!.trim().isNotEmpty) ...[
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
            if (!mounted || picked == null) return;
            setState(() => startAt = picked);
          },
          onPickEndDate: () async {
            final picked = await pickDateTime(
              context,
              initial: endAt ?? startAt,
            );
            if (!mounted || picked == null) return;
            setState(() => endAt = picked);
          },
          onFreeChanged: (value) {
            controller.setFree(value);
            if (value) {
              priceCtrl.value = priceCtrl.value.copyWith(
                text: '0',
                selection: const TextSelection.collapsed(offset: 1),
                composing: TextRange.empty,
              );
            }
          },
        ),
        const SizedBox(height: 12),
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
              AppEnvironment.validateAll();
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
          onClearLocation: state.submitting ? null : controller.clearSelectedLocation,
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: state.submitting ? null : () => submit(state, controller),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: state.submitting
                  ? const AppSpinner(size: 18, strokeWidth: 2)
                  : const Text('Publish'),
            ),
          ),
        ),
      ],
    );
  }

  void syncFreePrice(CreateEventState state) {
    if (!state.isFree) return;
    if (priceCtrl.text == '0') return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (priceCtrl.text == '0') return;
      priceCtrl.value = priceCtrl.value.copyWith(
        text: '0',
        selection: const TextSelection.collapsed(offset: 1),
        composing: TextRange.empty,
      );
    });
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

      final bytes = kIsWeb ? await file.readAsBytes() : null;

      newItems.add(
        EventImageUploadItem(
          localPath: file.path,
          isCover: false,
          previewBytes: bytes,
        ),
      );
    }

    if (newItems.isEmpty) return;
    controller.addGalleryImages(newItems);
  }

  Future<void> submit(
    CreateEventState state,
    CreateEventController controller,
  ) async {
    final title = titleCtrl.text.trim();
    final description = descriptionCtrl.text.trim();
    final capacity = int.tryParse(capacityCtrl.text.trim());
    final price = state.isFree ? 0.0 : double.tryParse(priceCtrl.text.trim());
    final selectedLocation = state.selectedLocation;

    if (title.length < 3 || title.length > 200) {
      controller.setFormError('Title must be between 3 and 200 characters.');
      return;
    }

    if (description.length < 10 || description.length > 4000) {
      controller.setFormError(
        'Description must be between 10 and 4000 characters.',
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

    if (!startAt!.isAfter(DateTime.now())) {
      controller.setFormError('Start date must be in the future.');
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

    final createdEvent = await controller.submit(
      title: title,
      description: description,
      segmentId: state.segmentId,
      genreId: state.genreId,
      subGenreId: state.subGenreId,
      latitude: selectedLocation.latitude,
      longitude: selectedLocation.longitude,
      startDateTime: startAt!,
      endDateTime: endAt!,
      capacity: capacity,
      price: price,
      tags: nullableString(tagsCtrl.text),
      accessibilityInfo: nullableString(accessibilityCtrl.text),
      promoterName: nullableString(promoterCtrl.text),
      locale: 'bs-BA',
    );

    if (!mounted || createdEvent == null) return;

    triggerEventMapRefresh(ref);

    await widget.onCreated?.call(
      CreateEventSuccessResult(
        eventId: createdEvent.eventId,
        title: createdEvent.title,
        latitude: selectedLocation.latitude,
        longitude: selectedLocation.longitude,
        published: true,
      ),
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

    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
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
}