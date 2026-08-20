import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geo_event/core/config/app_environment.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/utils/date_time_extensions.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/feedback/app_loading_indicator.dart';
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
  final _scrollController = ScrollController();

  ProviderSubscription<CreateEventState>? _stateSubscription;

  static const int maxImageBytes = 10 * 1000 * 1000;

  DateTime? startAt;
  DateTime? endAt;

  @override
  void initState() {
    super.initState();

    Future.microtask(
      () => ref.read(createEventControllerProvider.notifier).loadInitial(),
    );

    _stateSubscription = ref.listenManual<CreateEventState>(
      createEventControllerProvider,
      (previous, next) {
        final previousError = previous?.errorMessage?.trim() ?? '';
        final nextError = next.errorMessage?.trim() ?? '';

        final previousSuccess = previous?.successMessage?.trim() ?? '';
        final nextSuccess = next.successMessage?.trim() ?? '';

        if ((previousError.isEmpty && nextError.isNotEmpty) ||
            (previousSuccess.isEmpty && nextSuccess.isNotEmpty)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            scrollToTop();
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _stateSubscription?.close();
    _scrollController.dispose();
    titleCtrl.dispose();
    descriptionCtrl.dispose();
    capacityCtrl.dispose();
    priceCtrl.dispose();
    tagsCtrl.dispose();
    accessibilityCtrl.dispose();
    promoterCtrl.dispose();
    super.dispose();
  }

  Future<void> scrollToTop() async {
    if (!_scrollController.hasClients) return;

    await _scrollController.animateTo(
      _scrollController.position.minScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createEventControllerProvider);
    final controller = ref.read(createEventControllerProvider.notifier);
    final theme = Theme.of(context);

    syncFreePrice(state);

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
          const AppLoadingIndicator(
            title: 'Loading event form',
            message: 'Please wait while we prepare everything.',
            centered: false,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),
        ],
        if (_hasMessage(state.errorMessage)) ...[
          InlineBanner(
            message: state.errorMessage!.trim(),
            isError: true,
          ),
          const SizedBox(height: 12),
        ],
        if (_hasMessage(state.successMessage)) ...[
          InlineBanner(
            message: state.successMessage!.trim(),
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
          onPickStartDate: state.submitting
              ? null
              : () async {
                  final picked = await pickDateTime(context, initial: startAt);
                  if (!mounted || picked == null) return;
                  setState(() => startAt = picked);
                },
          onPickEndDate: state.submitting
              ? null
              : () async {
                  final picked = await pickDateTime(
                    context,
                    initial: endAt ?? startAt,
                  );
                  if (!mounted || picked == null) return;
                  setState(() => endAt = picked);
                },
          onFreeChanged: state.submitting
              ? null
              : (value) {
                  controller.setFree(value);
                  if (value) {
                    _setPriceText('0');
                  }
                },
        ),
        const SizedBox(height: 12),
        CreateEventImagePicker(
          state: state,
          onPickFeaturedImage: state.submitting
              ? null
              : () => pickFeaturedImage(controller),
          onPickGalleryImages: state.submitting
              ? null
              : () => pickGalleryImages(controller, state),
          onClearFeaturedImage:
              state.submitting ? null : controller.clearFeaturedImage,
          onRemoveGalleryImageAt:
              state.submitting ? null : controller.removeGalleryImageAt,
        ),
        const SizedBox(height: 12),
        CreateEventTaxonomySection(
          state: state,
          onSegmentChanged: state.submitting ? null : controller.selectSegment,
          onGenreChanged: state.submitting ? null : controller.selectGenre,
          onSubGenreChanged:
              state.submitting ? null : controller.selectSubGenre,
        ),
        const SizedBox(height: 12),
        CreateEventLocationPicker(
          state: state,
          onTapPickLocation: state.submitting
              ? null
              : () async {
                  try {
                    AppEnvironment.validateAll();
                  } catch (error, stackTrace) {
                    AppLogger.error(
                      'Mapbox configuration validation failed.',
                      tag: 'CreateEventScreen',
                      error: error,
                      stackTrace: stackTrace,
                    );

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
          onClearLocation:
              state.submitting ? null : controller.clearSelectedLocation,
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
      _setPriceText('0');
    });
  }

  void _setPriceText(String value) {
    priceCtrl.value = priceCtrl.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
      composing: TextRange.empty,
    );
  }

  Future<void> pickFeaturedImage(CreateEventController controller) async {
    try {
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
    } catch (error, stackTrace) {
      controller.setFormError(
        ErrorMapper.toMessage(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Could not pick the featured image.',
        ),
      );
      AppLogger.error(
        'Failed to pick featured image.',
        tag: 'CreateEventScreen',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> pickGalleryImages(
    CreateEventController controller,
    CreateEventState state,
  ) async {
    try {
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
    } catch (error, stackTrace) {
      controller.setFormError(
        ErrorMapper.toMessage(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Could not pick gallery images.',
        ),
      );
      AppLogger.error(
        'Failed to pick gallery images.',
        tag: 'CreateEventScreen',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> submit(
    CreateEventState state,
    CreateEventController controller,
  ) async {
    final title = titleCtrl.text.trim();
    final description = descriptionCtrl.text.trim();
    final capacityError = Validators.nonNegativeInt(
      capacityCtrl.text,
      fieldName: 'Capacity',
    );
    final priceError = state.isFree
        ? null
        : Validators.positiveNumber(
            priceCtrl.text,
            fieldName: 'Price',
          );

    final capacity = int.tryParse(capacityCtrl.text.trim());
    final price = state.isFree ? 0.0 : double.tryParse(priceCtrl.text.trim());
    final selectedLocation = state.selectedLocation;

    if (Validators.minLength(title, length: 3, fieldName: 'Title') != null ||
        Validators.maxLength(title, length: 200, fieldName: 'Title') != null) {
      controller.setFormError('Title must be between 3 and 200 characters.');
      return;
    }

    if (Validators.minLength(
              description,
              length: 10,
              fieldName: 'Description',
            ) !=
            null ||
        Validators.maxLength(
              description,
              length: 4000,
              fieldName: 'Description',
            ) !=
            null) {
      controller.setFormError(
        'Description must be between 10 and 4000 characters.',
      );
      return;
    }

    if (capacityError != null || capacity == null || capacity > 1000000) {
      controller.setFormError('Capacity must be between 0 and 1,000,000.');
      return;
    }

    if (priceError != null || price == null || price > 100000) {
      controller.setFormError('Price must be between 0 and 100000.');
      return;
    }

    if (startAt == null || endAt == null) {
      controller.setFormError('Please select both start and end date.');
      return;
    }

    if (!startAt!.isAfter(DateTime.now().toUtc())) {
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

    try {
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
    } catch (error, stackTrace) {
      controller.setFormError(
        ErrorMapper.toMessage(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Could not create the event.',
        ),
      );
      AppLogger.error(
        'Failed to create event.',
        tag: 'CreateEventScreen',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<DateTime?> pickDateTime(
    BuildContext context, {
    DateTime? initial,
  }) async {
    final now = DateTime.now().toUtc();
    final today = now.dateOnly;
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

  Future<String?> validatePickedImageWithSize(XFile file) async {
    final bytes = await file.readAsBytes();

    if (!_hasValidImageSignature(bytes)) {
      return 'Only valid JPG, PNG, or WEBP image files are allowed.';
    }

    if (bytes.length > maxImageBytes) {
      return 'Image must be smaller than 10 MB.';
    }

    return null;
  }

  bool _hasValidImageSignature(Uint8List bytes) {
    if (bytes.length < 12) return false;

    final isJpg =
        bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;

    final isPng =
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47;

    final isWebP =
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50;

    return isJpg || isPng || isWebP;
  }

  static String formatDateTime(DateTime value) {
    return value.formatDateTime(pattern: 'dd.MM.yyyy HH:mm');
  }

  static String? nullableString(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static bool _hasMessage(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}