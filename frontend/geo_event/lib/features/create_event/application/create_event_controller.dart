import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../shared/events/data/events_repository.dart';
import '../../../shared/events/models/create_event_models.dart';
import '../../../shared/events/models/create_event_state.dart';
import '../../../shared/events/providers/event_providers.dart';
import '../../../shared/my_events/models/my_event_response_dto.dart';

final createEventControllerProvider =
    StateNotifierProvider.autoDispose<CreateEventController, CreateEventState>(
  (ref) {
    return CreateEventController(
      ref: ref,
      repository: ref.watch(eventsRepositoryProvider),
    );
  },
);

class CreateEventController extends StateNotifier<CreateEventState> {
  CreateEventController({
    required this.ref,
    required this.repository,
  }) : super(const CreateEventState());

  final Ref ref;
  final EventsRepository repository;

  Future<void> loadInitial() async {
    state = state.copyWith(
      loadingInitial: true,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    );

    try {
      final segments = await repository.getSegments();

      state = state.copyWith(
        loadingInitial: false,
        segments: segments,
      );
    } catch (error, stackTrace) {
      state = state.copyWith(
        loadingInitial: false,
        errorMessage: _messageFromError(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to load event categories.',
        ),
        clearSuccessMessage: true,
      );
    }
  }

  Future<void> selectSegment(int? id) async {
    state = state.copyWith(
      segmentId: id,
      clearGenreId: true,
      clearSubGenreId: true,
      genres: const [],
      subGenres: const [],
      genresLoading: id != null,
      subGenresLoading: false,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    );

    if (id == null) {
      state = state.copyWith(
        genresLoading: false,
      );
      return;
    }

    try {
      final genres = await repository.getGenresBySegment(id);

      state = state.copyWith(
        genresLoading: false,
        genres: genres,
      );
    } catch (error, stackTrace) {
      state = state.copyWith(
        genresLoading: false,
        errorMessage: _messageFromError(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to load genres for this segment.',
        ),
        clearSuccessMessage: true,
      );
    }
  }

  Future<void> selectGenre(int? id) async {
    state = state.copyWith(
      genreId: id,
      clearSubGenreId: true,
      subGenres: const [],
      subGenresLoading: id != null,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    );

    if (id == null) {
      state = state.copyWith(
        subGenresLoading: false,
      );
      return;
    }

    try {
      final subGenres = await repository.getSubGenresByGenre(id);

      state = state.copyWith(
        subGenresLoading: false,
        subGenres: subGenres,
      );
    } catch (error, stackTrace) {
      state = state.copyWith(
        subGenresLoading: false,
        errorMessage: _messageFromError(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to load subgenres for this genre.',
        ),
        clearSuccessMessage: true,
      );
    }
  }

  void selectSubGenre(int? id) {
    state = state.copyWith(
      subGenreId: id,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    );
  }

  void hydrateForEdit(MyEventResponseDto event) {
    final locationTitle = 'Selected location';

    final subtitle =
        '${event.latitude.toStringAsFixed(6)}, '
        '${event.longitude.toStringAsFixed(6)}';

    state = state.copyWith(
      eventId: event.eventId,
      segmentId: event.segmentId,
      genreId: event.genreId,
      subGenreId: event.subGenreId,
      isFree: event.price <= 0,
      selectedLocation: MapboxPlace(
        id: 'event-${event.eventId}',
        title: locationTitle,
        subtitle: subtitle,
        latitude: event.latitude,
        longitude: event.longitude,
      ),
      existingImages: event.images,
      removedImageIds: const [],
      clearErrorMessage: true,
      clearSuccessMessage: true,
    );
  }

  void setFree(bool value) {
    state = state.copyWith(
      isFree: value,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    );
  }

  void setSelectedLocation(MapboxPlace place) {
    state = state.copyWith(
      selectedLocation: place,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    );
  }

  void clearSelectedLocation() {
    state = state.copyWith(
      clearSelectedLocation: true,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    );
  }

  void setFeaturedImage(EventImageUploadItem? image) {
    state = state.copyWith(
      featuredImage: image,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    );
  }

  void clearFeaturedImage() {
    state = state.copyWith(
      clearFeaturedImage: true,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    );
  }

  void addGalleryImages(List<EventImageUploadItem> images) {
    final existingPaths = <String>{
      ...state.galleryImages.map((image) => image.localPath),
      if (state.featuredImage != null) state.featuredImage!.localPath,
    };

    final uniqueNewImages = images.where((image) {
      return existingPaths.add(image.localPath);
    }).toList(growable: false);

    if (uniqueNewImages.isEmpty) {
      return;
    }

    state = state.copyWith(
      galleryImages: [
        ...state.galleryImages,
        ...uniqueNewImages,
      ],
      clearErrorMessage: true,
      clearSuccessMessage: true,
    );
  }

  void removeGalleryImageAt(int index) {
    if (index < 0 || index >= state.galleryImages.length) {
      return;
    }

    final updated = [...state.galleryImages]..removeAt(index);

    state = state.copyWith(
      galleryImages: updated,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    );
  }

  void removeExistingImage(int imageId) {
    final image = state.existingImages.cast<EventImageDto?>().firstWhere(
          (item) => item?.imageId == imageId,
          orElse: () => null,
        );

    if (image == null) {
      return;
    }

    state = state.copyWith(
      existingImages: state.existingImages
          .where((item) => item.imageId != imageId)
          .toList(growable: false),
      removedImageIds: {
        ...state.removedImageIds,
        imageId,
      }.toList(growable: false),
      clearErrorMessage: true,
      clearSuccessMessage: true,
    );
  }

  void setFormError(String message) {
    state = state.copyWith(
      errorMessage: message,
      clearSuccessMessage: true,
    );
  }

  void clearMessages() {
    state = state.copyWith(
      clearErrorMessage: true,
      clearSuccessMessage: true,
    );
  }

  Future<EventItem?> submit({
    required String title,
    required String description,
    required int? segmentId,
    required int? genreId,
    required int? subGenreId,
    required double latitude,
    required double longitude,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required int capacity,
    required double price,
    required String? tags,
    required String? accessibilityInfo,
    required String? promoterName,
    required String locale,
  }) async {
    state = state.copyWith(
      submitting: true,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    );

    try {
      final now = DateTime.now().toUtc();
      final cleanTitle = title.trim();
      final cleanDescription = description.trim();
      final cleanLocale = locale.trim().isEmpty ? 'bs-BA' : locale.trim();
      final cleanTags = _cleanNullable(tags);
      final cleanAccessibilityInfo = _cleanNullable(accessibilityInfo);
      final cleanPromoterName = _cleanNullable(promoterName);
      final normalizedPrice = state.isFree ? 0.0 : price;
      final isEditing = state.eventId != null;

      if (segmentId == null || segmentId <= 0) {
        throw Exception('Please select a segment.');
      }

      if (genreId == null || genreId <= 0) {
        throw Exception('Please select a genre.');
      }

      if (subGenreId != null && subGenreId <= 0) {
        throw Exception('Invalid subgenre selected.');
      }

      if (cleanTitle.length < 3 || cleanTitle.length > 200) {
        throw Exception('Title must be between 3 and 200 characters.');
      }

      if (cleanDescription.length < 10 || cleanDescription.length > 4000) {
        throw Exception(
          'Description must be between 10 and 4000 characters.',
        );
      }

      if (latitude < -90 || latitude > 90) {
        throw Exception('Latitude must be between -90 and 90.');
      }

      if (longitude < -180 || longitude > 180) {
        throw Exception('Longitude must be between -180 and 180.');
      }

      if (!startDateTime.toUtc().isAfter(now)) {
        throw Exception('Start date must be in the future.');
      }

      if (!endDateTime.toUtc().isAfter(startDateTime.toUtc())) {
        throw Exception('End date must be after start date.');
      }

      if (capacity < 0 || capacity > 1000000) {
        throw Exception('Capacity must be between 0 and 1,000,000.');
      }

      if (normalizedPrice < 0 || normalizedPrice > 100000) {
        throw Exception('Price must be between 0 and 100000.');
      }

      if (cleanTags != null && cleanTags.length > 500) {
        throw Exception('Tags must be 500 characters or fewer.');
      }

      if (cleanAccessibilityInfo != null &&
          cleanAccessibilityInfo.length > 1000) {
        throw Exception(
          'Accessibility information must be 1000 characters or fewer.',
        );
      }

      if (cleanPromoterName != null && cleanPromoterName.length > 200) {
        throw Exception('Promoter name must be 200 characters or fewer.');
      }

      if (cleanLocale.length > 10) {
        throw Exception('Locale must be 10 characters or fewer.');
      }

      final payload = CreateEventRequest(
        title: cleanTitle,
        description: cleanDescription,
        segmentId: segmentId,
        genreId: genreId,
        subGenreId: subGenreId,
        latitude: latitude,
        longitude: longitude,
        startDateTime: startDateTime.toUtc(),
        endDateTime: endDateTime.toUtc(),
        capacity: capacity,
        price: normalizedPrice,
        tags: cleanTags,
        accessibilityInfo: cleanAccessibilityInfo,
        promoterName: cleanPromoterName,
        locale: cleanLocale,
      );

      final event = isEditing
          ? await repository.updateEvent(
              state.eventId!,
              payload,
            )
          : await repository.createEvent(payload);

      final eventId = event.eventId;
      String? warning;

      final deleteError = await _deleteRemovedImages(
        eventId: eventId,
      );

      if (deleteError != null) {
        warning = deleteError;
      }

      final imageError = await _attachSelectedImagesToEvent(
        eventId: eventId,
      );

      if (imageError != null) {
        warning = warning == null
            ? 'Event saved, but some image operations failed:\n$imageError'
            : '$warning\n$imageError';
      }

      EventItem finalEvent = event;
      String successMessage;

      if (isEditing) {
        successMessage = 'Event updated successfully.';
      } else {
        await repository.publishEvent(eventId);

        finalEvent = event.copyWith(
          status: 'Published',
        );

        successMessage = 'Event published successfully.';
      }

      state = state.copyWith(
        submitting: false,
        eventId: eventId,
        clearFeaturedImage: true,
        galleryImages: const [],
        removedImageIds: const [],
        successMessage: successMessage,
        errorMessage: warning,
      );

      return finalEvent;
    } catch (error, stackTrace) {
      state = state.copyWith(
        submitting: false,
        errorMessage: _messageFromError(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to save the event.',
        ),
        clearSuccessMessage: true,
      );

      return null;
    }
  }

  Future<String?> _deleteRemovedImages({
    required int eventId,
  }) async {
    if (state.removedImageIds.isEmpty) {
      return null;
    }

    final failures = <String>[];

    for (final imageId in state.removedImageIds) {
      try {
        await repository.deleteEventImage(
          eventId: eventId,
          imageId: imageId,
        );
      } catch (error, stackTrace) {
        failures.add(
          'Image #$imageId: ${_messageFromError(
            error,
            stackTrace: stackTrace,
            fallbackMessage: 'Could not remove this image.',
          )}',
        );
      }
    }

    if (failures.isEmpty) {
      return null;
    }

    return 'Event saved, but some existing images could not be removed:\n'
        '${failures.join('\n')}';
  }

  Future<String?> _attachSelectedImagesToEvent({
    required int eventId,
  }) async {
    final uploadedPaths = <String>{};
    final failures = <String>[];

    final featured = state.featuredImage;

    if (featured != null) {
      try {
        await _uploadAndAttachImage(
          eventId: eventId,
          image: featured,
          isCover: true,
        );

        uploadedPaths.add(featured.localPath);
      } catch (error, stackTrace) {
        failures.add(
          'Featured image: ${_messageFromError(
            error,
            stackTrace: stackTrace,
            fallbackMessage: 'Could not upload the featured image.',
          )}',
        );
      }
    }

    for (final image in state.galleryImages) {
      if (uploadedPaths.contains(image.localPath)) {
        continue;
      }

      try {
        await _uploadAndAttachImage(
          eventId: eventId,
          image: image,
          isCover: false,
        );

        uploadedPaths.add(image.localPath);
      } catch (error, stackTrace) {
        failures.add(
          '${image.fileName}: ${_messageFromError(
            error,
            stackTrace: stackTrace,
            fallbackMessage: 'Could not upload this image.',
          )}',
        );
      }
    }

    if (failures.isEmpty) {
      return null;
    }

    return failures.join('\n');
  }

  Future<void> _uploadAndAttachImage({
    required int eventId,
    required EventImageUploadItem image,
    required bool isCover,
  }) async {
    final imageUrl = await repository.uploadImage(
      image.localPath,
      fileName: image.fileName,
      bytes: image.previewBytes,
    );

    await repository.addEventImage(
      eventId: eventId,
      imageUrl: imageUrl,
      isCover: isCover,
    );
  }

  String? _cleanNullable(String? value) {
    final trimmed = value?.trim();

    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  String _messageFromError(
    Object error, {
    StackTrace? stackTrace,
    required String fallbackMessage,
  }) {
    return ErrorMapper.toMessage(
      error,
      stackTrace: stackTrace,
      fallbackMessage: fallbackMessage,
    );
  }
}