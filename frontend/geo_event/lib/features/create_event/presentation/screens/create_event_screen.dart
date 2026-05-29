import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/config/app_env.dart';
import '../../application/create_event_controller.dart';
import '../../../../shared/location/data/mapbox_places_service.dart';
import '../../../../shared/events/models/create_event_models.dart';
import '../../../../shared/events/models/create_event_state.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _externalUrlCtrl = TextEditingController();
  final _accessibilityCtrl = TextEditingController();
  final _promoterCtrl = TextEditingController();
  final _imagePicker = ImagePicker();

  static const int _maxImageBytes = 10 * 1000 * 1000;
  static const _allowedImageExtensions = {'.jpg', '.jpeg', '.png', '.webp'};

  DateTime? _startAt;
  DateTime? _endAt;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(createEventControllerProvider.notifier).loadInitial(),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _capacityCtrl.dispose();
    _priceCtrl.dispose();
    _tagsCtrl.dispose();
    _externalUrlCtrl.dispose();
    _accessibilityCtrl.dispose();
    _promoterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createEventControllerProvider);
    final controller = ref.read(createEventControllerProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          'Fill in the details, save a draft, or publish your event.',
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
          _InlineBanner(
            message: state.errorMessage!,
            isError: true,
          ),
          const SizedBox(height: 12),
        ],
        if (state.successMessage != null && state.successMessage!.trim().isNotEmpty) ...[
          _InlineBanner(
            message: state.successMessage!,
            isError: false,
          ),
          const SizedBox(height: 12),
        ],
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel('Basic info'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Write a title for your event',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionCtrl,
                minLines: 5,
                maxLines: 7,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Write a description for your event',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel('Images'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: state.submitting
                          ? null
                          : () => _pickFeaturedImage(controller),
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
                _ImagePreviewTile(
                  item: state.featuredImage!,
                  title: 'Featured image',
                  subtitle: 'This will be used as the cover image.',
                  onRemove: controller.clearFeaturedImage,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: state.submitting
                          ? null
                          : () => _pickGalleryImages(controller, state),
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
                      return _GalleryImageCard(
                        item: image,
                        onRemove: () => controller.removeGalleryImageAt(index),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel('Attendance & schedule'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _capacityCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Capacity',
                  hintText: 'How many people will attend?',
                ),
              ),
              const SizedBox(height: 12),
              _PickerField(
                label: 'Start date',
                value: _startAt == null
                    ? 'Pick a starting date'
                    : _formatDateTime(_startAt!),
                onTap: () async {
                  final picked = await _pickDateTime(context, initial: _startAt);
                  if (picked != null && mounted) {
                    setState(() => _startAt = picked);
                  }
                },
              ),
              const SizedBox(height: 12),
              _PickerField(
                label: 'End date',
                value: _endAt == null
                    ? 'Pick an ending date'
                    : _formatDateTime(_endAt!),
                onTap: () async {
                  final picked = await _pickDateTime(
                    context,
                    initial: _endAt ?? _startAt,
                  );
                  if (picked != null && mounted) {
                    setState(() => _endAt = picked);
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel('Category'),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: state.segmentId,
                isExpanded: true,
                items: state.segments
                    .map(
                      (item) => DropdownMenuItem<int>(
                        value: item.segmentId,
                        child: Text(item.name),
                      ),
                    )
                    .toList(),
                onChanged: state.submitting ? null : (value) => controller.selectSegment(value),
                decoration: const InputDecoration(labelText: 'Segment'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: state.genreId,
                isExpanded: true,
                items: state.genres
                    .map(
                      (item) => DropdownMenuItem<int>(
                        value: item.genreId,
                        child: Text(item.name),
                      ),
                    )
                    .toList(),
                onChanged: state.segmentId == null || state.genresLoading || state.submitting
                    ? null
                    : (value) => controller.selectGenre(value),
                decoration: const InputDecoration(labelText: 'Genre'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: state.subGenreId,
                isExpanded: true,
                items: state.subGenres
                    .map(
                      (item) => DropdownMenuItem<int>(
                        value: item.subGenreId,
                        child: Text(item.name),
                      ),
                    )
                    .toList(),
                onChanged: state.genreId == null || state.subGenresLoading || state.submitting
                    ? null
                    : (value) => controller.selectSubGenre(value),
                decoration: const InputDecoration(labelText: 'Subgenre'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel('Location'),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: state.isOnline
                    ? null
                    : () async {
                        try {
                          AppEnv.validate();
                        } catch (_) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'MAPBOX_ACCESS_TOKEN is missing. Run the app with --dart-define=MAPBOX_ACCESS_TOKEN=your_token',
                              ),
                            ),
                          );
                          return;
                        }

                        final picked = await showModalBottomSheet<MapboxPlace>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const _LocationSearchSheet(),
                        );

                        if (picked != null) {
                          controller.setSelectedLocation(picked);
                        }
                      },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Location',
                    suffixIcon: const Icon(Icons.location_on_outlined),
                    enabled: !state.isOnline,
                  ),
                  child: Text(
                    state.isOnline
                        ? 'Online event does not require a physical location'
                        : (state.selectedLocation?.title ?? 'Search for a place'),
                    style: TextStyle(
                      fontSize: 14,
                      color: state.selectedLocation == null && !state.isOnline
                          ? theme.textTheme.bodySmall?.color
                          : null,
                    ),
                  ),
                ),
              ),
              if (state.selectedLocation != null && !state.isOnline) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF161A21) : const Color(0xFFF9FBFD),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2A303A) : const Color(0xFFE3EAF3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.selectedLocation!.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if ((state.selectedLocation!.subtitle ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          state.selectedLocation!.subtitle!,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: controller.clearSelectedLocation,
                          child: const Text('Clear'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel('Pricing & details'),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                value: state.isFree,
                onChanged: (value) {
                  controller.setFree(value);
                  if (value) {
                    _priceCtrl.text = '0';
                  }
                },
                contentPadding: EdgeInsets.zero,
                title: const Text('Free'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtrl,
                enabled: !state.isFree,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Price'),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                value: state.isOnline,
                onChanged: (value) {
                  controller.setOnline(value);
                  if (value) {
                    controller.clearSelectedLocation();
                  }
                },
                contentPadding: EdgeInsets.zero,
                title: const Text('Online event'),
              ),
              if (state.isOnline) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _externalUrlCtrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(labelText: 'External URL'),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _tagsCtrl,
                decoration: const InputDecoration(labelText: 'Tags'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _promoterCtrl,
                decoration: const InputDecoration(labelText: 'Promoter name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _accessibilityCtrl,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Accessibility info'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: state.submitting
                    ? null
                    : () => _submit(state, controller, publish: false),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: state.submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save draft'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: state.submitting
                    ? null
                    : () => _submit(state, controller, publish: true),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: state.submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Publish'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickFeaturedImage(CreateEventController controller) async {
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
  }

  Future<void> _pickGalleryImages(
    CreateEventController controller,
    CreateEventState state,
  ) async {
    final files = await _imagePicker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;

    final existingPaths = <String>{
      if (state.featuredImage != null) state.featuredImage!.localPath,
      ...state.galleryImages.map((e) => e.localPath),
    };

    final newItems = <EventImageUploadItem>[];

    for (final file in files) {
      if (existingPaths.contains(file.path)) {
        continue;
      }

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
  }

  Future<void> _submit(
    CreateEventState state,
    CreateEventController controller, {
    required bool publish,
  }) async {
    final title = _titleCtrl.text.trim();
    final description = _descriptionCtrl.text.trim();
    final capacity = int.tryParse(_capacityCtrl.text.trim());
    final price = state.isFree ? 0.0 : double.tryParse(_priceCtrl.text.trim());
    final externalUrl = _nullable(_externalUrlCtrl.text);

    if (title.length < 3 || title.length > 200) {
      controller.setFormError('Title must be between 3 and 200 characters.');
      return;
    }

    if (description.length < 10 || description.length > 5000) {
      controller.setFormError('Description must be between 10 and 5000 characters.');
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

    if (_startAt == null || _endAt == null) {
      controller.setFormError('Please select both start and end date.');
      return;
    }

    if (_startAt!.isBefore(DateTime.now())) {
      controller.setFormError('Start date must be in the future.');
      return;
    }

    if (!_endAt!.isAfter(_startAt!)) {
      controller.setFormError('End date must be after start date.');
      return;
    }

    if (state.isOnline && (externalUrl == null || externalUrl.isEmpty)) {
      controller.setFormError(
        'Please provide an external URL for an online event.',
      );
      return;
    }

    final selectedLocation = state.selectedLocation;
    if (!state.isOnline && selectedLocation == null) {
      controller.setFormError('Please choose a location.');
      return;
    }

    if (state.isOnline && selectedLocation == null) {
      controller.setFormError(
        'Online events still need a location until the API accepts null coordinates.',
      );
      return;
    }

    await controller.submit(
      title: title,
      description: description,
      segmentId: state.segmentId,
      genreId: state.genreId,
      subGenreId: state.subGenreId,
      venueId: null,
      cityId: null,
      latitude: selectedLocation!.latitude,
      longitude: selectedLocation.longitude,
      startDateTime: _startAt!,
      endDateTime: _endAt!,
      capacity: capacity,
      price: price,
      isOnline: state.isOnline,
      tags: _nullable(_tagsCtrl.text),
      externalUrl: externalUrl,
      accessibilityInfo: _nullable(_accessibilityCtrl.text),
      promoterName: _nullable(_promoterCtrl.text),
      locale: 'bs-BA',
      publish: publish,
    );
  }

  String? _validatePickedImage(XFile file) {
    final path = file.path.toLowerCase();

    final hasAllowedExtension = _allowedImageExtensions.any(
      (ext) => path.endsWith(ext),
    );

    if (!hasAllowedExtension) {
      return 'Only JPG, PNG, and WEBP images are allowed.';
    }

    return null;
  }

  Future<int?> _readImageSize(XFile file) async {
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

  Future<String?> _validatePickedImageWithSize(XFile file) async {
    final typeError = _validatePickedImage(file);
    if (typeError != null) return typeError;

    final size = await _readImageSize(file);
    if (size == null) {
      return 'Could not read the selected image.';
    }

    if (size > _maxImageBytes) {
      return 'Image must be smaller than 10 MB.';
    }

    return null;
  }

  Future<DateTime?> _pickDateTime(
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

  static String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final yyyy = local.year.toString();
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dd.$mm.$yyyy  $hh:$min';
  }

  static String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _LocationSearchSheet extends ConsumerStatefulWidget {
  const _LocationSearchSheet();

  @override
  ConsumerState<_LocationSearchSheet> createState() =>
      _LocationSearchSheetState();
}

class _LocationSearchSheetState extends ConsumerState<_LocationSearchSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  bool _loading = false;
  String? _error;
  List<MapboxPlace> _results = const [];

  @override
  void initState() {
    super.initState();
    if (AppEnv.mapboxToken.isEmpty) {
      _error =
          'MAPBOX_ACCESS_TOKEN is missing. Run the app with --dart-define=MAPBOX_ACCESS_TOKEN=your_token';
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (AppEnv.mapboxToken.isEmpty) {
      setState(() {
        _results = const [];
        _loading = false;
        _error =
            'MAPBOX_ACCESS_TOKEN is missing. Run the app with --dart-define=MAPBOX_ACCESS_TOKEN=your_token';
      });
      return;
    }

    if (query.trim().length < 2) {
      setState(() {
        _results = const [];
        _error = null;
        _loading = false;
      });
      return;
    }

    final service = ref.read(mapboxPlacesServiceProvider);

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await service.searchPlaces(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _results = const [];
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161A21) : const Color(0xFFF9FBFD),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 5,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.18)
                    : Colors.black.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Choose location',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              autofocus: true,
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(
                  const Duration(milliseconds: 350),
                  () => _performSearch(value),
                );
              },
              decoration: const InputDecoration(
                hintText: 'Search place or address',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _results.isEmpty
                          ? const Center(
                              child: Text('Start typing to search for a place.'),
                            )
                          : ListView.separated(
                              itemCount: _results.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final item = _results[index];
                                return InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () => Navigator.of(context).pop(item),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF2A303A)
                                            : const Color(0xFFE3EAF3),
                                      ),
                                      color: isDark
                                          ? const Color(0xFF1B2028)
                                          : Colors.white,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if ((item.subtitle ?? '').isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            item.subtitle!,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF17191D) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF2A303A) : const Color(0xFFE5EAF2),
        ),
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _PickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          value,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}

class _InlineBanner extends StatelessWidget {
  final String message;
  final bool isError;

  const _InlineBanner({
    required this.message,
    required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isError ? theme.colorScheme.error : theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.28),
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 13,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ImagePreviewTile extends StatelessWidget {
  final EventImageUploadItem item;
  final String title;
  final String subtitle;
  final VoidCallback onRemove;

  const _ImagePreviewTile({
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
            child: _LocalImage(
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

class _GalleryImageCard extends StatelessWidget {
  final EventImageUploadItem item;
  final VoidCallback onRemove;

  const _GalleryImageCard({
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
            child: _LocalImage(
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

class _LocalImage extends StatelessWidget {
  final EventImageUploadItem item;
  final double width;
  final double height;

  const _LocalImage({
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
        errorBuilder: (_, __, ___) =>
            _ImageFallback(width: width, height: height),
      );
    }

    if (!kIsWeb) {
      return Image.file(
        File(item.localPath),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            _ImageFallback(width: width, height: height),
      );
    }

    return _ImageFallback(width: width, height: height);
  }
}

class _ImageFallback extends StatelessWidget {
  final double width;
  final double height;

  const _ImageFallback({
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