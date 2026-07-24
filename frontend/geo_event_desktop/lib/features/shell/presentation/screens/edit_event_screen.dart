import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/theme/app_theme_metrics.dart';
import '../../../../core/utils/date_time_extensions.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/admin_profile/data/admin_events_repository.dart';
import '../../../../shared/admin_profile/models/admin_event.dart';
import '../../../../shared/admin_profile/models/categories.dart';
import '../../../../shared/admin_profile/providers/admin_categories_providers.dart';
import '../../../../shared/map/models/mapbox_place.dart';
import '../../../../shared/map/providers/mapbox_providers.dart';

class EditEventScreen extends ConsumerStatefulWidget {
  const EditEventScreen({
    super.key,
    required this.event,
    required this.repository,
  });

  final AdminEvent event;
  final AdminEventsRepository repository;

  @override
  ConsumerState<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends ConsumerState<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _capacityController = TextEditingController();
  final _priceController = TextEditingController();
  final _tagsController = TextEditingController();
  final _accessibilityInfoController = TextEditingController();
  final _promoterNameController = TextEditingController();
  final _locationSearchController = TextEditingController();
  final _scrollController = ScrollController();

  Timer? _locationDebounce;

  bool _isSubmitting = false;
  bool _isLoadingCategories = true;
  bool _isSearchingLocations = false;
  bool _isUploadingCover = false;
  bool _isUploadingGallery = false;
  bool _isFeatured = false;
  bool _isFree = false;

  DateTime? _startDateTime;
  DateTime? _endDateTime;

  int? _selectedSegmentId;
  int? _selectedGenreId;
  int? _selectedSubGenreId;

  List<AdminSegment> _segments = const [];
  List<AdminGenre> _allGenres = const [];
  List<AdminSubGenre> _allSubGenres = const [];

  MapboxPlace? _selectedPlace;
  List<MapboxPlace> _locationResults = const [];

  final List<ExistingImageItem> _existingImages = [];
  PendingUploadImage? _newCoverImage;
  final List<PendingUploadImage> _newGalleryImages = [];

  String? _uploadedCoverUrl;
  final List<String> _uploadedGalleryUrls = [];

  @override
  void initState() {
    super.initState();

    final event = widget.event;
    _titleController.text = event.title;
    _descriptionController.text = event.description;
    _capacityController.text = event.capacity.toString();
    _priceController.text = _formatPrice(event.price);
    _tagsController.text = event.tags ?? '';
    _accessibilityInfoController.text = event.accessibilityInfo ?? '';
    _promoterNameController.text = event.promoterName ?? '';

    _startDateTime = event.startDateTime;
    _endDateTime = event.endDateTime;
    _selectedSegmentId = event.segmentId;
    _selectedGenreId = event.genreId;
    _selectedSubGenreId = event.subGenreId;
    _isFeatured = event.isFeatured;
    _isFree = event.price <= 0;

    if (event.latitude != 0 || event.longitude != 0) {
      _selectedPlace = MapboxPlace(
        id: 'event-${event.eventId}',
        title: event.displayTitle,
        subtitle: event.locationLabel,
        latitude: event.latitude,
        longitude: event.longitude,
      );
      _locationSearchController.text = event.locationLabel;
    }

    for (final image in event.images) {
      if (image.imageUrl.trim().isEmpty) continue;

      _existingImages.add(
        ExistingImageItem(
          imageId: image.imageId,
          imageUrl: image.imageUrl.trim(),
          isCover: image.isCover,
        ),
      );
    }

    _loadCategories();
    _hydrateInitialLocationLabel();
  }

  @override
  void dispose() {
    _locationDebounce?.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    _priceController.dispose();
    _tagsController.dispose();
    _accessibilityInfoController.dispose();
    _promoterNameController.dispose();
    _locationSearchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);

    try {
      final api = ref.read(adminCategoriesApiProvider);
      final segments = await api.getSegments();
      final genresPage = await api.getGenresPage(page: 1, pageSize: 300);
      final subGenresPage = await api.getSubGenresPage(page: 1, pageSize: 500);

      if (!mounted) return;

      setState(() {
        _segments = segments;
        _allGenres = genresPage.items;
        _allSubGenres = subGenresPage.items;
        _isLoadingCategories = false;
      });
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to load categories for admin edit event.',
        tag: 'EditEventScreen',
        error: error,
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      setState(() => _isLoadingCategories = false);
      _showMessage(
        ErrorMapper.toMessage(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Could not load categories.',
        ),
      );
    }
  }

  Future<void> _hydrateInitialLocationLabel() async {
    if (!AppEnvironment.hasMapbox) return;
    if (widget.event.latitude == 0 && widget.event.longitude == 0) return;

    try {
      final api = ref.read(mapboxReverseGeocodingApiProvider);
      final place = await api.reverseGeocode(
        latitude: widget.event.latitude,
        longitude: widget.event.longitude,
      );

      if (!mounted || place == null) return;

      setState(() {
        _selectedPlace = place;
        _locationSearchController.text =
            place.subtitle?.trim().isNotEmpty == true
                ? place.subtitle!
                : place.title;
      });
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Failed to reverse geocode initial admin event location.',
        tag: 'EditEventScreen',
      );
      AppLogger.error(
        'Initial admin location reverse geocoding error.',
        tag: 'EditEventScreen',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  List<AdminGenre> get _genresForSelectedSegment {
    if (_selectedSegmentId == null) return const [];
    return _allGenres.where((e) => e.segmentId == _selectedSegmentId).toList();
  }

  List<AdminSubGenre> get _subGenresForSelectedGenre {
    if (_selectedGenreId == null) return const [];
    return _allSubGenres.where((e) => e.genreId == _selectedGenreId).toList();
  }

  Future<void> _searchLocations(String query) async {
    _locationDebounce?.cancel();

    if (!AppEnvironment.hasMapbox) {
      setState(() {
        _locationResults = const [];
        _isSearchingLocations = false;
      });
      return;
    }

    if (query.trim().length < 2) {
      setState(() {
        _locationResults = const [];
        _isSearchingLocations = false;
      });
      return;
    }

    _locationDebounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;

      setState(() => _isSearchingLocations = true);

      try {
        final service = ref.read(mapboxPlacesServiceProvider);
        final found = await service.searchLocations(query.trim());

        if (!mounted) return;

        setState(() {
          _locationResults = found;
          _isSearchingLocations = false;
        });
      } catch (error, stackTrace) {
        AppLogger.error(
          'Location search failed for admin edit event.',
          tag: 'EditEventScreen',
          error: error,
          stackTrace: stackTrace,
        );

        if (!mounted) return;

        setState(() {
          _locationResults = const [];
          _isSearchingLocations = false;
        });

        _showMessage(
          ErrorMapper.toMessage(
            error,
            stackTrace: stackTrace,
            fallbackMessage: 'Could not search locations.',
          ),
        );
      }
    });
  }

  void _selectLocation(MapboxPlace place) {
    setState(() {
      _selectedPlace = place;
      _locationResults = const [];
      _locationSearchController.text =
          place.subtitle?.trim().isNotEmpty == true
              ? place.subtitle!
              : place.title;
    });

    FocusScope.of(context).unfocus();
  }

  Future<void> _pickCoverImage() async {
    if (_isSubmitting || _isUploadingCover) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final validationError = _validatePickedImage(file);

    if (validationError != null) {
      _showMessage(validationError);
      return;
    }

    setState(() {
      _newCoverImage = PendingUploadImage.fromPlatformFile(
        file,
        isCover: true,
      );
    });
  }

  Future<void> _pickGalleryImages() async {
    if (_isSubmitting || _isUploadingGallery) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final existingKeys = <String>{
      if (_newCoverImage != null) _newCoverImage!.identityKey,
      ..._newGalleryImages.map((e) => e.identityKey),
    };

    final added = <PendingUploadImage>[];

    for (final file in result.files) {
      final validationError = _validatePickedImage(file);

      if (validationError != null) {
        _showMessage(validationError);
        continue;
      }

      final item = PendingUploadImage.fromPlatformFile(
        file,
        isCover: false,
      );

      if (existingKeys.contains(item.identityKey)) continue;
      existingKeys.add(item.identityKey);
      added.add(item);
    }

    if (added.isEmpty) return;

    setState(() {
      _newGalleryImages.addAll(added);
    });
  }

  String? _validatePickedImage(PlatformFile file) {
    final bytes = file.bytes;

    if (bytes == null || bytes.isEmpty) {
      return 'Could not read selected image bytes.';
    }

    if (!_hasValidImageSignature(bytes)) {
      return 'Only valid JPG, PNG, or WEBP image files are allowed.';
    }

    const maxImageBytes = 10 * 1000 * 1000;
    if (bytes.length > maxImageBytes) {
      return 'Image must be smaller than 10 MB.';
    }

    if (!kIsWeb && (file.path == null || file.path!.trim().isEmpty)) {
      return 'Selected image path is invalid.';
    }

    return null;
  }

  bool _hasValidImageSignature(Uint8List bytes) {
    if (bytes.length < 12) return false;

    final isJpg = bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;
    final isPng = bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47;
    final isWebP = bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50;

    return isJpg || isPng || isWebP;
  }

  void _clearPickedCoverImage() {
    setState(() {
      _newCoverImage = null;
      _uploadedCoverUrl = null;
    });
  }

  void _removePickedGalleryImageAt(int index) {
    setState(() {
      _newGalleryImages.removeAt(index);
      if (index < _uploadedGalleryUrls.length) {
        _uploadedGalleryUrls.removeAt(index);
      }
    });
  }

  Future<void> _removeExistingImage(ExistingImageItem image) async {
  if (_isSubmitting || _isUploadingCover || _isUploadingGallery) return;

  try {
    await widget.repository.deleteEventImage(
      eventId: widget.event.eventId,
      imageId: image.imageId,
    );

    if (!mounted) return;

    setState(() {
      _existingImages.removeWhere((e) => e.imageId == image.imageId);

      if (image.isCover) {
        _uploadedCoverUrl = null;
      }
    });

    _showMessage('Image removed successfully.');
  } catch (error, stackTrace) {
    AppLogger.error(
      'Failed to delete event image.',
      tag: 'EditEventScreen',
      error: error,
      stackTrace: stackTrace,
    );

    if (!mounted) return;

    _showMessage(
      ErrorMapper.toMessage(
        error,
        stackTrace: stackTrace,
        fallbackMessage: 'Could not remove image.',
      ),
    );
  }
}

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate() || _isSubmitting) return;

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final capacity = int.tryParse(_capacityController.text.trim());
    final price = _isFree ? 0.0 : double.tryParse(_priceController.text.trim());

    if (_startDateTime == null || _endDateTime == null) {
      _showMessage('Please select both start and end date.');
      await _scrollToTop();
      return;
    }

    if (!_endDateTime!.isAfter(_startDateTime!)) {
      _showMessage('End date must be after start date.');
      await _scrollToTop();
      return;
    }

    if (_selectedPlace == null) {
      _showMessage('Please choose a location.');
      await _scrollToTop();
      return;
    }

    if (_selectedSegmentId == null) {
      _showMessage('Please select a segment.');
      await _scrollToTop();
      return;
    }

    if (_selectedGenreId == null) {
      _showMessage('Please select a genre.');
      await _scrollToTop();
      return;
    }

    if (_selectedSubGenreId == null) {
      _showMessage('Please select a subgenre.');
      await _scrollToTop();
      return;
    }

    final capacityError = Validators.nonNegativeInt(
      _capacityController.text,
      fieldName: 'Capacity',
    );

    if (capacityError != null || capacity == null || capacity > 1000000) {
      _showMessage('Capacity must be between 0 and 1,000,000.');
      await _scrollToTop();
      return;
    }

    if (!_isFree) {
      final priceError = Validators.positiveNumber(
        _priceController.text,
        fieldName: 'Price',
      );

      if (priceError != null || price == null || price > 100000) {
        _showMessage('Price must be between 0 and 100000 KM.');
        await _scrollToTop();
        return;
      }
    }

    FocusScope.of(context).unfocus();

    setState(() => _isSubmitting = true);

    try {
      final updatedEvent = await widget.repository.updateEvent(
        eventId: widget.event.eventId,
        segmentId: _selectedSegmentId,
        genreId: _selectedGenreId,
        subGenreId: _selectedSubGenreId,
        title: title,
        description: description,
        latitude: _selectedPlace!.latitude,
        longitude: _selectedPlace!.longitude,
        startDateTime: _startDateTime,
        endDateTime: _endDateTime,
        capacity: capacity,
        price: price,
        isFeatured: _isFeatured,
        tags: _nullableString(_tagsController.text),
        accessibilityInfo: _nullableString(_accessibilityInfoController.text),
        promoterName: _nullableString(_promoterNameController.text),
        locale: _nullableString(widget.event.locale) ?? 'bs-BA',
      );

      final eventWithImages = await _uploadPendingImages(updatedEvent);

      if (!mounted) return;

      _showMessage(
        _uploadedCoverUrl != null || _uploadedGalleryUrls.isNotEmpty
            ? 'Event updated and images saved successfully.'
            : 'Event updated successfully.',
      );

      context.pop(eventWithImages);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to submit edited admin event.',
        tag: 'EditEventScreen',
        error: error,
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      _showMessage(
        ErrorMapper.toMessage(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Could not save event changes.',
        ),
      );

      await _scrollToTop();
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<AdminEvent> _uploadPendingImages(AdminEvent updatedEvent) async {
  var refreshedEvent = updatedEvent;
  final eventId = widget.event.eventId;

  if (_newCoverImage != null) {
    setState(() => _isUploadingCover = true);

    try {
      final uploadedUrl = await widget.repository.uploadEventImage(
        _newCoverImage!.localPath,
        fileName: _newCoverImage!.fileName,
        bytes: _newCoverImage!.bytes,
      );

      final existingCover = _existingImages.where((e) => e.isCover).firstOrNull;
      if (existingCover != null) {
        await widget.repository.deleteEventImage(
          eventId: eventId,
          imageId: existingCover.imageId,
        );

        _existingImages.removeWhere((e) => e.imageId == existingCover.imageId);
      }

      await widget.repository.addEventImage(
        eventId: eventId,
        imageUrl: uploadedUrl,
        isCover: true,
      );

      if (!mounted) return refreshedEvent;

      setState(() {
        _uploadedCoverUrl = uploadedUrl;
        _isUploadingCover = false;

        _existingImages.removeWhere((e) => e.isCover);
        _existingImages.add(
          ExistingImageItem(
            imageId: -DateTime.now().microsecondsSinceEpoch,
            imageUrl: uploadedUrl,
            isCover: true,
          ),
        );

        _newCoverImage = null;
      });
    } catch (error, stackTrace) {
      if (mounted) {
        setState(() => _isUploadingCover = false);
      }

      AppLogger.error(
        'Failed to upload or attach admin cover image.',
        tag: 'EditEventScreen',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  if (_newGalleryImages.isNotEmpty) {
    setState(() => _isUploadingGallery = true);

    try {
      final uploadedUrls = await widget.repository.uploadEventImages(
        _newGalleryImages.map((e) => e.localPath).toList(growable: false),
        fileNames: _newGalleryImages.map((e) => e.fileName).toList(growable: false),
        bytesList: _newGalleryImages.map((e) => e.bytes).toList(growable: false),
      );

      for (final url in uploadedUrls) {
        await widget.repository.addEventImage(
          eventId: eventId,
          imageUrl: url,
          isCover: false,
        );
      }

      if (!mounted) return refreshedEvent;

      setState(() {
        _uploadedGalleryUrls
          ..clear()
          ..addAll(uploadedUrls);

        _isUploadingGallery = false;

        for (final url in uploadedUrls) {
          _existingImages.add(
            ExistingImageItem(
              imageId: -DateTime.now().microsecondsSinceEpoch - _existingImages.length,
              imageUrl: url,
              isCover: false,
            ),
          );
        }

        _newGalleryImages.clear();
      });
    } catch (error, stackTrace) {
      if (mounted) {
        setState(() => _isUploadingGallery = false);
      }

      AppLogger.error(
        'Failed to upload or attach admin gallery images.',
        tag: 'EditEventScreen',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  return refreshedEvent;
}

  Future<void> _scrollToTop() async {
    if (!_scrollController.hasClients) return;

    await _scrollController.animateTo(
      _scrollController.position.minScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Future<DateTime?> _pickDateTime(DateTime? initial) async {
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

    if (date == null || !mounted) return null;

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

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static String? _nullableString(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _formatPrice(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
  }

  static String _formatDateTime(DateTime? value) {
    if (value == null) return 'Select date and time';
    return value.formatDateTime(pattern: 'dd.MM.yyyy HH:mm');
  }

  Color _statusColor(ThemeData theme, String status) {
    switch (status.trim().toLowerCase()) {
      case 'confirmed':
        return theme.colorScheme.primary;
      case 'pending':
        return Colors.orange.shade800;
      case 'cancelled':
        return theme.colorScheme.error;
      case 'completed':
        return const Color(0xFF2B7A4B);
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  Widget _buildSectionCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(18),
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final displayTitle = _titleController.text.trim().isEmpty
        ? widget.event.displayTitle
        : _titleController.text.trim();

    final visibleExistingCover =
        _existingImages.where((e) => e.isCover).toList(growable: false);
    final visibleExistingGallery =
        _existingImages.where((e) => !e.isCover).toList(growable: false);

    final previewCoverUrl =
        _uploadedCoverUrl ?? visibleExistingCover.firstOrNull?.imageUrl;
    final previewCoverBytes = _newCoverImage?.bytes;

    final subtitle = _selectedPlace?.subtitle?.trim().isNotEmpty == true
        ? _selectedPlace!.subtitle!
        : _selectedPlace?.title ?? widget.event.category;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: Center(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: colorScheme.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton.icon(
                      onPressed: _isSubmitting ? null : () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Back'),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Edit Event',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Update event details, categories, location, and images.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EventCoverPreview(
                          imageUrl: previewCoverUrl,
                          memoryBytes: previewCoverBytes,
                          fallbackLabel: displayTitle.isNotEmpty
                              ? displayTitle.characters.first.toUpperCase()
                              : 'E',
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayTitle,
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Current status: ${widget.event.displayStatus}',
                                style: textTheme.bodySmall?.copyWith(
                                  color: _statusColor(theme, widget.event.status),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    _buildSectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Basic info',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 14),
                          EditEventField(
                            controller: _titleController,
                            label: 'Title',
                            hintText: 'Write a title for your event',
                            prefixIcon: Icons.title_rounded,
                            enabled: !_isSubmitting,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              final text = (value ?? '').trim();
                              if (text.length < 3 || text.length > 200) {
                                return 'Title must be between 3 and 200 characters.';
                              }
                              return null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 14),
                          EditEventTextAreaField(
                            controller: _descriptionController,
                            label: 'Description',
                            hintText: 'Write a description for your event',
                            prefixIcon: Icons.description_outlined,
                            enabled: !_isSubmitting,
                            maxLines: 6,
                            validator: (value) {
                              final text = (value ?? '').trim();
                              if (text.length < 10 || text.length > 4000) {
                                return 'Description must be between 10 and 4000 characters.';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    _buildSectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attendance schedule',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 14),
                          EditEventField(
                            controller: _capacityController,
                            label: 'Capacity',
                            hintText: 'How many people can attend?',
                            prefixIcon: Icons.groups_2_outlined,
                            enabled: !_isSubmitting,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              final error = Validators.nonNegativeInt(
                                value,
                                fieldName: 'Capacity',
                              );
                              if (error != null) return error;

                              final parsed = int.tryParse((value ?? '').trim());
                              if (parsed == null || parsed > 1000000) {
                                return 'Capacity must be between 0 and 1,000,000.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          DateFieldButton(
                            label: 'Start date',
                            value: _formatDateTime(_startDateTime),
                            icon: Icons.event_available_outlined,
                            enabled: !_isSubmitting,
                            onTap: () async {
                              final picked = await _pickDateTime(_startDateTime);
                              if (picked != null && mounted) {
                                setState(() => _startDateTime = picked);
                              }
                            },
                          ),
                          const SizedBox(height: 14),
                          DateFieldButton(
                            label: 'End date',
                            value: _formatDateTime(_endDateTime),
                            icon: Icons.event_busy_outlined,
                            enabled: !_isSubmitting,
                            onTap: () async {
                              final picked =
                                  await _pickDateTime(_endDateTime ?? _startDateTime);
                              if (picked != null && mounted) {
                                setState(() => _endDateTime = picked);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    _buildSectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pricing details',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Free event'),
                            value: _isFree,
                            onChanged: _isSubmitting
                                ? null
                                : (value) {
                                    setState(() {
                                      _isFree = value;
                                      if (value) _priceController.text = '0';
                                    });
                                  },
                          ),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Featured event'),
                            subtitle: const Text('Mark this event as featured'),
                            value: _isFeatured,
                            onChanged: _isSubmitting
                                ? null
                                : (value) => setState(() => _isFeatured = value),
                          ),
                          const SizedBox(height: 8),
                          EditEventField(
                            controller: _priceController,
                            label: 'Ticket price',
                            hintText: _isFree ? 'Free event selected' : '0.00',
                            suffixText: _isFree ? null : 'KM',
                            helperText: _isFree
                                ? 'No ticket price needed for free events. Currency BAM KM.'
                                : 'Currency BAM KM.',
                            prefixIcon: Icons.payments_outlined,
                            enabled: !_isFree && !_isSubmitting,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              if (_isFree) return null;
                              final parsed = double.tryParse((value ?? '').trim());
                              if (parsed == null || parsed <= 0 || parsed > 100000) {
                                return 'Price must be between 0 and 100000 KM.';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    _buildSectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Category',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (_isLoadingCategories)
                            const Center(child: CircularProgressIndicator())
                          else ...[
                            DropdownField<int>(
                              label: 'Segment',
                              value: _selectedSegmentId,
                              items: _segments
                                  .map(
                                    (item) => DropdownMenuItem<int>(
                                      value: item.segmentId,
                                      child: Text(item.name),
                                    ),
                                  )
                                  .toList(),
                              enabled: !_isSubmitting,
                              onChanged: (value) {
                                setState(() {
                                  _selectedSegmentId = value;
                                  _selectedGenreId = null;
                                  _selectedSubGenreId = null;
                                });
                              },
                            ),
                            const SizedBox(height: 14),
                            DropdownField<int>(
                              label: 'Genre',
                              value: _selectedGenreId,
                              items: _genresForSelectedSegment
                                  .map(
                                    (item) => DropdownMenuItem<int>(
                                      value: item.genreId,
                                      child: Text(item.name),
                                    ),
                                  )
                                  .toList(),
                              enabled: !_isSubmitting && _selectedSegmentId != null,
                              onChanged: (value) {
                                setState(() {
                                  _selectedGenreId = value;
                                  _selectedSubGenreId = null;
                                });
                              },
                            ),
                            const SizedBox(height: 14),
                            DropdownField<int>(
                              label: 'Subgenre',
                              value: _selectedSubGenreId,
                              items: _subGenresForSelectedGenre
                                  .map(
                                    (item) => DropdownMenuItem<int>(
                                      value: item.subGenreId,
                                      child: Text(item.name),
                                    ),
                                  )
                                  .toList(),
                              enabled: !_isSubmitting && _selectedGenreId != null,
                              onChanged: (value) {
                                setState(() => _selectedSubGenreId = value);
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    _buildSectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          EditEventField(
                            controller: _locationSearchController,
                            label: 'Search location',
                            hintText: AppEnvironment.hasMapbox
                                ? 'Search place or address'
                                : 'Mapbox is not configured',
                            prefixIcon: Icons.search_rounded,
                            enabled: !_isSubmitting && AppEnvironment.hasMapbox,
                            onChanged: _searchLocations,
                          ),
                          if (_isSearchingLocations) ...[
                            const SizedBox(height: 10),
                            const LinearProgressIndicator(minHeight: 2),
                          ],
                          if (_locationResults.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: colorScheme.outlineVariant),
                              ),
                              child: Column(
                                children: _locationResults
                                    .map(
                                      (item) => ListTile(
                                        leading: const Icon(Icons.location_on_outlined),
                                        title: Text(item.title.trim()),
                                        subtitle: item.subtitle?.trim().isNotEmpty == true
                                            ? Text(item.subtitle!.trim())
                                            : null,
                                        onTap: () => _selectLocation(item),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                          if (_selectedPlace != null) ...[
                            const SizedBox(height: 12),
                            SelectedLocationCard(
                              place: _selectedPlace!,
                              enabled: !_isSubmitting,
                              onClear: () {
                                setState(() {
                                  _selectedPlace = null;
                                  _locationSearchController.clear();
                                  _locationResults = const [];
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    _buildSectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Images',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Cover and gallery images are linked to the event after upload.',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isSubmitting ? null : _pickCoverImage,
                                  icon: _isUploadingCover
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.star_border_rounded),
                                  label: Text(
                                    _newCoverImage == null
                                        ? 'Choose cover image'
                                        : 'Replace cover image',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_newCoverImage != null) ...[
                            const SizedBox(height: 12),
                            LocalImagePreviewTile(
                              item: _newCoverImage!,
                              title: 'Selected cover image',
                              subtitle: 'This file will be uploaded and attached on save.',
                              onRemove: _isSubmitting ? null : _clearPickedCoverImage,
                            ),
                          ],
                          if (visibleExistingCover.isNotEmpty && _newCoverImage == null) ...[
                            const SizedBox(height: 12),
                            ExistingImagePreviewTile(
                              image: visibleExistingCover.first,
                              title: 'Current cover image',
                              subtitle: 'Currently attached to this event.',
                              onDelete: _isSubmitting
                                  ? null
                                  : () => _removeExistingImage(visibleExistingCover.first),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isSubmitting ? null : _pickGalleryImages,
                                  icon: _isUploadingGallery
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.photo_library_outlined),
                                  label: const Text('Add gallery images'),
                                ),
                              ),
                            ],
                          ),
                          if (_newGalleryImages.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: List.generate(
                                _newGalleryImages.length,
                                (index) => GalleryUploadCard(
                                  item: _newGalleryImages[index],
                                  onRemove: _isSubmitting
                                      ? null
                                      : () => _removePickedGalleryImageAt(index),
                                ),
                              ),
                            ),
                          ],
                          if (visibleExistingGallery.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: visibleExistingGallery
                                  .map(
                                    (image) => RemoteGalleryCard(
                                      image: image,
                                      onDelete: _isSubmitting
                                          ? null
                                          : () => _removeExistingImage(image),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                          if (visibleExistingGallery.isEmpty &&
                              _newGalleryImages.isEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              'No gallery images attached yet.',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    _buildSectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Additional details',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 14),
                          EditEventField(
                            controller: _tagsController,
                            label: 'Tags',
                            hintText: 'music, techno, live, outdoor',
                            prefixIcon: Icons.sell_outlined,
                            enabled: !_isSubmitting,
                          ),
                          const SizedBox(height: 14),
                          EditEventField(
                            controller: _promoterNameController,
                            label: 'Promoter name',
                            hintText: 'Enter promoter name',
                            prefixIcon: Icons.campaign_outlined,
                            enabled: !_isSubmitting,
                          ),
                          const SizedBox(height: 14),
                          EditEventTextAreaField(
                            controller: _accessibilityInfoController,
                            label: 'Accessibility info',
                            hintText:
                                'Wheelchair access, elevator, accessible toilet...',
                            prefixIcon: Icons.accessible_forward_outlined,
                            enabled: !_isSubmitting,
                            maxLines: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              onPressed: _isSubmitting ? null : () => context.pop(),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: colorScheme.outlineVariant),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppThemeMetrics.radiusMd * 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppThemeMetrics.radiusMd * 2,
                                  ),
                                ),
                              ),
                              child: _isSubmitting
                                  ? SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          colorScheme.onPrimary,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      'Save changes',
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.onPrimary,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ExistingImageItem {
  const ExistingImageItem({
    required this.imageId,
    required this.imageUrl,
    required this.isCover,
  });

  final int imageId;
  final String imageUrl;
  final bool isCover;
}

class PendingUploadImage {
  const PendingUploadImage({
    required this.localPath,
    required this.fileName,
    required this.bytes,
    required this.isCover,
  });

  factory PendingUploadImage.fromPlatformFile(
    PlatformFile file, {
    required bool isCover,
  }) {
    return PendingUploadImage(
      localPath: file.path ?? file.name,
      fileName: file.name,
      bytes: file.bytes!,
      isCover: isCover,
    );
  }

  final String localPath;
  final String fileName;
  final Uint8List bytes;
  final bool isCover;

  String get identityKey => '$fileName|$localPath|${bytes.length}';
}

class EventCoverPreview extends StatelessWidget {
  const EventCoverPreview({
    super.key,
    required this.imageUrl,
    required this.memoryBytes,
    required this.fallbackLabel,
  });

  final String? imageUrl;
  final Uint8List? memoryBytes;
  final String fallbackLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    ImageProvider<Object>? imageProvider;
    if (memoryBytes != null) {
      imageProvider = MemoryImage(memoryBytes!);
    } else if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      imageProvider = NetworkImage(imageUrl!.trim());
    }

    return Container(
      width: 112,
      height: 112,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        image: imageProvider != null
            ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
            : null,
      ),
      child: imageProvider == null
          ? Text(
              fallbackLabel,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );
  }
}

class SelectedLocationCard extends StatelessWidget {
  const SelectedLocationCard({
    super.key,
    required this.place,
    required this.enabled,
    required this.onClear,
  });

  final MapboxPlace place;
  final bool enabled;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            place.title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          if (place.subtitle?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(place.subtitle!.trim(), style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: 8),
          Text(
            'Lat ${place.latitude.toStringAsFixed(5)}, Lng ${place.longitude.toStringAsFixed(5)}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: enabled ? onClear : null,
              child: const Text('Clear'),
            ),
          ),
        ],
      ),
    );
  }
}

class ExistingImagePreviewTile extends StatelessWidget {
  const ExistingImagePreviewTile({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
    required this.onDelete,
  });

  final ExistingImageItem image;
  final String title;
  final String subtitle;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              image.imageUrl,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 72,
                height: 72,
                color: theme.colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: 'Delete image',
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class RemoteGalleryCard extends StatelessWidget {
  const RemoteGalleryCard({
    super.key,
    required this.image,
    required this.onDelete,
  });

  final ExistingImageItem image;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 112,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              image.imageUrl,
              width: 112,
              height: 112,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 112,
                height: 112,
                color: theme.colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: onDelete,
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class LocalImagePreviewTile extends StatelessWidget {
  const LocalImagePreviewTile({
    super.key,
    required this.item,
    required this.title,
    required this.subtitle,
    required this.onRemove,
  });

  final PendingUploadImage item;
  final String title;
  final String subtitle;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(
              item.bytes,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 72,
                height: 72,
                color: theme.colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: const Icon(Icons.image_not_supported_outlined),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            tooltip: 'Remove image',
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class GalleryUploadCard extends StatelessWidget {
  const GalleryUploadCard({
    super.key,
    required this.item,
    required this.onRemove,
  });

  final PendingUploadImage item;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 96,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(
              item.bytes,
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 96,
                height: 96,
                color: theme.colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: const Icon(Icons.image_not_supported_outlined),
              ),
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

class EditEventField extends StatelessWidget {
  const EditEventField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.validator,
    this.enabled = true,
    this.textInputAction,
    this.keyboardType,
    this.onChanged,
    this.suffixText,
    this.helperText,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final bool enabled;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final String? suffixText;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppThemeMetrics.radiusMd),
      borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          validator: validator,
          textInputAction: textInputAction,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest,
            hintText: hintText,
            suffixText: suffixText,
            helperText: helperText,
            prefixIcon: Icon(prefixIcon),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: border,
            enabledBorder: border,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppThemeMetrics.radiusMd),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppThemeMetrics.radiusMd),
              borderSide: BorderSide(color: theme.colorScheme.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppThemeMetrics.radiusMd),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class EditEventTextAreaField extends StatelessWidget {
  const EditEventTextAreaField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.validator,
    this.enabled = true,
    this.maxLines = 5,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final bool enabled;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppThemeMetrics.radiusMd),
      borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          validator: validator,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest,
            hintText: hintText,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(bottom: 76),
              child: Icon(prefixIcon),
            ),
            alignLabelWithHint: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: border,
            enabledBorder: border,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppThemeMetrics.radiusMd),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppThemeMetrics.radiusMd),
              borderSide: BorderSide(color: theme.colorScheme.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppThemeMetrics.radiusMd),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DateFieldButton extends StatelessWidget {
  const DateFieldButton({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppThemeMetrics.radiusMd),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppThemeMetrics.radiusMd),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(value),
                ),
                const Icon(Icons.calendar_month_outlined),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class DropdownField<T> extends StatelessWidget {
  const DropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final bool enabled;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: items.any((item) => item.value == value) ? value : null,
          isExpanded: true,
          items: items,
          onChanged: enabled ? onChanged : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppThemeMetrics.radiusMd),
              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppThemeMetrics.radiusMd),
              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppThemeMetrics.radiusMd),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}