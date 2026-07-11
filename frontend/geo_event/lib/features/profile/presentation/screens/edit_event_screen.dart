import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geo_event/core/config/app_environment.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/utils/date_time_extensions.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/feedback/app_confirm_dialog.dart';
import '../../../../core/widgets/feedback/app_loading_indicator.dart';
import '../../../../core/widgets/feedback/app_spinner.dart';
import '../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../core/widgets/surfaces/app_surface_card.dart';
import '../../../../shared/events/models/create_event_models.dart';
import '../../../../shared/events/models/create_event_state.dart';
import '../../../../shared/events/providers/event_refresh_providers.dart';
import '../../../../shared/location/providers/location_providers.dart';
import '../../../../shared/my_events/models/my_event_response_dto.dart';
import '../../../create_event/application/create_event_controller.dart';
import '../../../create_event/presentation/widgets/create_event_form.dart';
import '../../../create_event/presentation/widgets/create_event_image_picker.dart';
import '../../../create_event/presentation/widgets/create_event_location_picker.dart';
import '../../../create_event/presentation/widgets/create_event_taxonomy_section.dart';

class EditEventScreen extends ConsumerStatefulWidget {
  const EditEventScreen({
    super.key,
    required this.event,
  });

  final MyEventResponseDto event;

  @override
  ConsumerState<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends ConsumerState<EditEventScreen> {
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _accessibilityCtrl = TextEditingController();
  final _promoterCtrl = TextEditingController();
  final _imagePicker = ImagePicker();
  final _scrollController = ScrollController();

  static const int _maxImageBytes = 10 * 1000 * 1000;

  late final ProviderSubscription<CreateEventState> _createEventSub;

  DateTime? _startAt;
  DateTime? _endAt;

  @override
  void initState() {
    super.initState();

    final event = widget.event;
    _titleCtrl.text = event.title;
    _descriptionCtrl.text = event.description;
    _capacityCtrl.text = event.capacity.toString();
    _priceCtrl.text = _formatPrice(event.price);
    _tagsCtrl.text = event.tags ?? '';
    _accessibilityCtrl.text = event.accessibilityInfo ?? '';
    _promoterCtrl.text = event.promoterName ?? '';
    _startAt = event.startDateTime;
    _endAt = event.endDateTime;

    _createEventSub = ref.listenManual<CreateEventState>(
      createEventControllerProvider,
      (previous, next) {
        final previousSuccess = previous?.successMessage?.trim() ?? '';
        final nextSuccess = next.successMessage?.trim() ?? '';

        final previousError = previous?.errorMessage?.trim() ?? '';
        final nextError = next.errorMessage?.trim() ?? '';

        if (previousError.isEmpty && nextError.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _scrollToTop();
          });
        }

        if (previousSuccess.isEmpty && nextSuccess.isNotEmpty && mounted) {
          triggerEventMapRefresh(ref);
          Navigator.of(context).pop(true);
        }
      },
    );

    Future.microtask(_loadInitialData);
  }

  Future<void> _loadInitialData() async {
    final controller = ref.read(createEventControllerProvider.notifier);

    try {
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

      final hasValidCoordinates =
          widget.event.latitude != 0 || widget.event.longitude != 0;

      if (!hasValidCoordinates) return;

      try {
        final place =
            await ref.read(mapboxReverseGeocodingApiProvider).reverseGeocode(
                  latitude: widget.event.latitude,
                  longitude: widget.event.longitude,
                );

        if (place != null && mounted) {
          controller.setSelectedLocation(place);
        }
      } catch (error, stackTrace) {
        AppLogger.warning(
          'Failed to reverse geocode existing event location.',
          tag: 'EditEventScreen',
        );
        AppLogger.error(
          'Reverse geocoding error.',
          tag: 'EditEventScreen',
          error: error,
          stackTrace: stackTrace,
        );
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to load edit event initial data.',
        tag: 'EditEventScreen',
        error: error,
        stackTrace: stackTrace,
      );

      controller.setFormError(
        ErrorMapper.toMessage(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Could not prepare the event form.',
        ),
      );
    }
  }

  @override
  void dispose() {
    _createEventSub.close();
    _scrollController.dispose();
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _capacityCtrl.dispose();
    _priceCtrl.dispose();
    _tagsCtrl.dispose();
    _accessibilityCtrl.dispose();
    _promoterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createEventControllerProvider);
    final controller = ref.read(createEventControllerProvider.notifier);
    final theme = Theme.of(context);

    _syncFreePrice(state);

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Edit event'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
          if (_hasMessage(state.errorMessage)) ...[
            InlineBanner(
              message: state.errorMessage!,
              isError: true,
            ),
            const SizedBox(height: 12),
          ],
          if (_hasMessage(state.successMessage)) ...[
            InlineBanner(
              message: state.successMessage!,
              isError: false,
            ),
            const SizedBox(height: 12),
          ],
          CreateEventForm(
            state: state,
            titleCtrl: _titleCtrl,
            descriptionCtrl: _descriptionCtrl,
            capacityCtrl: _capacityCtrl,
            priceCtrl: _priceCtrl,
            tagsCtrl: _tagsCtrl,
            accessibilityCtrl: _accessibilityCtrl,
            promoterCtrl: _promoterCtrl,
            startAt: _startAt,
            endAt: _endAt,
            formatDateTime: _formatDateTime,
            onPickStartDate: state.submitting
                ? null
                : () async {
                    final picked =
                        await _pickDateTime(context, initial: _startAt);
                    if (picked != null && mounted) {
                      setState(() => _startAt = picked);
                    }
                  },
            onPickEndDate: state.submitting
                ? null
                : () async {
                    final picked = await _pickDateTime(
                      context,
                      initial: _endAt ?? _startAt,
                    );
                    if (picked != null && mounted) {
                      setState(() => _endAt = picked);
                    }
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
          if (state.existingImages.isNotEmpty) ...[
            _ExistingImagesSection(
              images: state.existingImages,
              submitting: state.submitting,
              onRemove: controller.removeExistingImage,
            ),
            const SizedBox(height: 12),
          ],
          CreateEventImagePicker(
            state: state,
            onPickFeaturedImage: state.submitting
                ? null
                : () {
                    _pickFeaturedImage(controller);
                  },
            onPickGalleryImages: state.submitting
                ? null
                : () {
                    _pickGalleryImages(controller, state);
                  },
            onClearFeaturedImage:
                state.submitting ? null : controller.clearFeaturedImage,
            onRemoveGalleryImageAt:
                state.submitting ? null : controller.removeGalleryImageAt,
          ),
          const SizedBox(height: 12),
          CreateEventTaxonomySection(
            state: state,
            onSegmentChanged: state.submitting
                ? null
                : (value) {
                    controller.selectSegment(value);
                  },
            onGenreChanged: state.submitting
                ? null
                : (value) {
                    controller.selectGenre(value);
                  },
            onSubGenreChanged: state.submitting
                ? null
                : (value) {
                    controller.selectSubGenre(value);
                  },
          ),
          const SizedBox(height: 12),
          CreateEventLocationPicker(
            state: state,
            onTapPickLocation: state.submitting
                ? null
                : () {
                    _handlePickLocation(context, controller);
                  },
            onClearLocation:
                state.submitting ? null : controller.clearSelectedLocation,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed:
                  state.submitting ? null : () => _submit(state, controller),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: state.submitting
                    ? const AppSpinner(
                        size: 18,
                        strokeWidth: 2,
                        color: Colors.white,
                      )
                    : const Text('Save changes'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _scrollToTop() async {
    if (!_scrollController.hasClients) return;

    await _scrollController.animateTo(
      _scrollController.position.minScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _syncFreePrice(CreateEventState state) {
    if (!state.isFree) return;
    if (_priceCtrl.text == '0') return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_priceCtrl.text == '0') return;
      _setPriceText('0');
    });
  }

  void _setPriceText(String value) {
    _priceCtrl.value = _priceCtrl.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
      composing: TextRange.empty,
    );
  }

  Future<void> _handlePickLocation(
    BuildContext context,
    CreateEventController controller,
  ) async {
    try {
      AppEnvironment.validateAll();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Map environment validation failed.',
        tag: 'EditEventScreen',
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
      builder: (context) => const LocationSearchSheet(),
    );

    if (picked != null) {
      controller.setSelectedLocation(picked);
    }
  }

  Future<void> _pickFeaturedImage(CreateEventController controller) async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (file == null) return;

      final validationError = await _validatePickedImageWithSize(file);
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
      AppLogger.error(
        'Failed to pick featured image.',
        tag: 'EditEventScreen',
        error: error,
        stackTrace: stackTrace,
      );

      controller.setFormError(
        ErrorMapper.toMessage(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Could not select the featured image.',
        ),
      );
    }
  }

  Future<void> _pickGalleryImages(
    CreateEventController controller,
    CreateEventState state,
  ) async {
    try {
      final files = await _imagePicker.pickMultiImage(imageQuality: 85);
      if (files.isEmpty) return;

      final existingPaths = <String>{
        if (state.featuredImage != null) state.featuredImage!.localPath,
        ...state.galleryImages.map((e) => e.localPath),
      };

      final newItems = <EventImageUploadItem>[];

      for (final file in files) {
        if (existingPaths.contains(file.path)) continue;

        final validationError = await _validatePickedImageWithSize(file);
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
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to pick gallery images.',
        tag: 'EditEventScreen',
        error: error,
        stackTrace: stackTrace,
      );

      controller.setFormError(
        ErrorMapper.toMessage(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Could not select gallery images.',
        ),
      );
    }
  }

  Future<void> _submit(
    CreateEventState state,
    CreateEventController controller,
  ) async {
    final title = _titleCtrl.text.trim();
    final description = _descriptionCtrl.text.trim();
    final capacityError = Validators.nonNegativeInt(
      _capacityCtrl.text,
      fieldName: 'Capacity',
    );
    final priceError = state.isFree
        ? null
        : Validators.positiveNumber(
            _priceCtrl.text,
            fieldName: 'Price',
          );

    final capacity = int.tryParse(_capacityCtrl.text.trim());
    final price = state.isFree ? 0.0 : double.tryParse(_priceCtrl.text.trim());
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

    if (_startAt == null || _endAt == null) {
      controller.setFormError('Please select both start and end date.');
      return;
    }

    if (!_endAt!.isAfter(_startAt!)) {
      controller.setFormError('End date must be after start date.');
      return;
    }

    if (selectedLocation == null) {
      controller.setFormError('Please choose a location.');
      return;
    }

    try {
      await controller.submit(
        title: title,
        description: description,
        segmentId: state.segmentId,
        genreId: state.genreId,
        subGenreId: state.subGenreId,
        latitude: selectedLocation.latitude,
        longitude: selectedLocation.longitude,
        startDateTime: _startAt!,
        endDateTime: _endAt!,
        capacity: capacity,
        price: price,
        tags: _nullableString(_tagsCtrl.text),
        accessibilityInfo: _nullableString(_accessibilityCtrl.text),
        promoterName: _nullableString(_promoterCtrl.text),
        locale: widget.event.locale,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to submit edited event.',
        tag: 'EditEventScreen',
        error: error,
        stackTrace: stackTrace,
      );

      controller.setFormError(
        ErrorMapper.toMessage(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Could not save event changes.',
        ),
      );
    }
  }

  Future<DateTime?> _pickDateTime(
    BuildContext context, {
    DateTime? initial,
  }) async {
    final now = DateTime.now();
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

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<String?> _validatePickedImageWithSize(XFile file) async {
    final bytes = await file.readAsBytes();

    if (!_hasValidImageSignature(bytes)) {
      return 'Only valid JPG, PNG, or WEBP image files are allowed.';
    }

    if (bytes.length > _maxImageBytes) {
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

  static String _formatDateTime(DateTime value) {
    return value.formatDateTime(pattern: 'dd.MM.yyyy HH:mm');
  }

  static String? _nullableString(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _formatPrice(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
  }

  static bool _hasMessage(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}

class _ExistingImagesSection extends StatelessWidget {
  const _ExistingImagesSection({
    required this.images,
    required this.submitting,
    required this.onRemove,
  });

  final List<EventImageDto> images;
  final bool submitting;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cover = images.where((e) => e.isCover).toList();
    final gallery = images.where((e) => !e.isCover).toList();

    if (images.isEmpty) {
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
            'Remove images you no longer want on this event.',
            style: TextStyle(
              fontSize: 13,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          if (cover.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Cover image',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _RemovableRemoteEventImage(
              image: cover.first,
              height: 180,
              submitting: submitting,
              onRemove: onRemove,
            ),
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
                separatorBuilder: (context, index) =>
                    const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  return _RemovableRemoteEventImage(
                    image: gallery[index],
                    width: 92,
                    height: 92,
                    submitting: submitting,
                    onRemove: onRemove,
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

class _RemovableRemoteEventImage extends StatelessWidget {
  const _RemovableRemoteEventImage({
    required this.image,
    this.width,
    required this.height,
    required this.submitting,
    required this.onRemove,
  });

  final EventImageDto image;
  final double? width;
  final double height;
  final bool submitting;
  final ValueChanged<int> onRemove;

  Future<void> _confirmRemove(BuildContext context) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Remove image?',
      message: 'This image will be removed from the event.',
      confirmLabel: 'Remove',
      destructive: true,
    );

    if (confirmed == true) {
      onRemove(image.imageId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            image.imageUrl,
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
            errorBuilder: (context, error, stackTrace) => Container(
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
        ),
        Positioned(
          top: 6,
          right: 6,
          child: Material(
            color: Colors.black54,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: submitting ? null : () => _confirmRemove(context),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}