import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/events/data/events_api.dart';
import '../../../shared/events/models/create_event_models.dart';
import '../../../shared/events/models/create_event_state.dart';

final createEventControllerProvider =
    StateNotifierProvider<CreateEventController, CreateEventState>((ref) {
  return CreateEventController(
    api: ref.watch(eventsApiProvider),
  );
});

class CreateEventController extends StateNotifier<CreateEventState> {
  final EventsApi api;

  CreateEventController({
    required this.api,
  }) : super(const CreateEventState());

  Future<void> loadInitial() async {
    state = state.copyWith(
      loadingInitial: true,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    );

    try {
      final segments = await api.getSegments();
      state = state.copyWith(
        loadingInitial: false,
        segments: segments,
      );
    } catch (e) {
      state = state.copyWith(
        loadingInitial: false,
        errorMessage: _messageFromError(e),
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
    );

    if (id == null) {
      state = state.copyWith(genresLoading: false);
      return;
    }

    try {
      final genres = await api.getGenresBySegment(id);
      state = state.copyWith(
        genresLoading: false,
        genres: genres,
      );
    } catch (e) {
      state = state.copyWith(
        genresLoading: false,
        errorMessage: _messageFromError(e),
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
    );

    if (id == null) {
      state = state.copyWith(subGenresLoading: false);
      return;
    }

    try {
      final subGenres = await api.getSubGenresByGenre(id);
      state = state.copyWith(
        subGenresLoading: false,
        subGenres: subGenres,
      );
    } catch (e) {
      state = state.copyWith(
        subGenresLoading: false,
        errorMessage: _messageFromError(e),
      );
    }
  }

  void selectSubGenre(int? id) {
    state = state.copyWith(
      subGenreId: id,
      clearErrorMessage: true,
    );
  }

  void setOnline(bool value) {
    state = state.copyWith(
      isOnline: value,
      clearErrorMessage: true,
    );
  }

  void setFree(bool value) {
    state = state.copyWith(
      isFree: value,
      clearErrorMessage: true,
    );
  }

  void setSelectedLocation(MapboxPlace place) {
    state = state.copyWith(
      selectedLocation: place,
      clearErrorMessage: true,
    );
  }

  void clearSelectedLocation() {
    state = state.copyWith(
      clearSelectedLocation: true,
      clearErrorMessage: true,
    );
  }

  void setFeaturedImage(EventImageUploadItem? image) {
    state = state.copyWith(
      featuredImage: image,
      clearErrorMessage: true,
    );
  }

  void clearFeaturedImage() {
    state = state.copyWith(
      clearFeaturedImage: true,
      clearErrorMessage: true,
    );
  }

  void setGalleryImages(List<EventImageUploadItem> images) {
    final unique = <String, EventImageUploadItem>{};
    for (final image in images) {
      unique[image.localPath] = image;
    }

    state = state.copyWith(
      galleryImages: unique.values.toList(),
      clearErrorMessage: true,
    );
  }

  void addGalleryImages(List<EventImageUploadItem> images) {
    final existingPaths = <String>{
      ...state.galleryImages.map((e) => e.localPath),
      if (state.featuredImage != null) state.featuredImage!.localPath,
    };

    final uniqueNewImages = images.where((image) {
      return existingPaths.add(image.localPath);
    }).toList();

    state = state.copyWith(
      galleryImages: [...state.galleryImages, ...uniqueNewImages],
      clearErrorMessage: true,
    );
  }

  void removeGalleryImageAt(int index) {
    if (index < 0 || index >= state.galleryImages.length) return;

    final updated = [...state.galleryImages]..removeAt(index);
    state = state.copyWith(
      galleryImages: updated,
      clearErrorMessage: true,
    );
  }

  void setFormError(String message) {
    state = state.copyWith(
      errorMessage: message,
      clearSuccessMessage: true,
    );
  }

  Future<void> submit({
    required String title,
    required String description,
    required int? segmentId,
    required int? genreId,
    required int? subGenreId,
    required int? venueId,
    required int? cityId,
    required double latitude,
    required double longitude,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required int capacity,
    required double price,
    required bool isOnline,
    required String? tags,
    required String? externalUrl,
    required String? accessibilityInfo,
    required String? promoterName,
    required String locale,
    required bool publish,
  }) async {
    state = state.copyWith(
      submitting: true,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    );

    try {
      final cleanTitle = title.trim();
      final cleanDescription = description.trim();
      final cleanLocale = locale.trim().isEmpty ? 'bs-BA' : locale.trim();
      final cleanTags = _cleanNullable(tags);
      final cleanExternalUrl = _cleanNullable(externalUrl);
      final cleanAccessibilityInfo = _cleanNullable(accessibilityInfo);
      final cleanPromoterName = _cleanNullable(promoterName);

      if (cleanTitle.length < 3 || cleanTitle.length > 200) {
        throw Exception('Title must be between 3 and 200 characters.');
      }

      if (cleanDescription.length < 10 || cleanDescription.length > 5000) {
        throw Exception('Description must be between 10 and 5000 characters.');
      }

      if (startDateTime.isBefore(DateTime.now())) {
        throw Exception('Start date must be in the future.');
      }

      if (!endDateTime.isAfter(startDateTime)) {
        throw Exception('End date must be after start date.');
      }

      if (capacity < 0 || capacity > 1000000) {
        throw Exception('Capacity must be between 0 and 1,000,000.');
      }

      if (price < 0 || price > 100000) {
        throw Exception('Price must be between 0 and 100000.');
      }

      if (segmentId == null) {
        throw Exception('Please select a segment.');
      }

      if (genreId == null) {
        throw Exception('Please select a genre.');
      }

      if (subGenreId == null) {
        throw Exception('Please select a subgenre.');
      }

      if (isOnline) {
        if (cleanExternalUrl == null || cleanExternalUrl.isEmpty) {
          throw Exception('Please provide an external URL for an online event.');
        }
      }

      final payload = CreateEventRequest(
        title: cleanTitle,
        description: cleanDescription,
        segmentId: segmentId,
        genreId: genreId,
        subGenreId: subGenreId,
        venueId: venueId,
        cityId: cityId,
        latitude: latitude,
        longitude: longitude,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        capacity: capacity,
        price: price,
        isOnline: isOnline,
        tags: cleanTags,
        externalUrl: cleanExternalUrl,
        accessibilityInfo: cleanAccessibilityInfo,
        promoterName: cleanPromoterName,
        locale: cleanLocale,
      );

      final event = state.eventId == null
          ? await api.createEvent(payload)
          : await api.updateEvent(state.eventId!, payload);

      final eventId = event.eventId;

      final imageError = await _attachSelectedImagesToEvent(eventId: eventId);
      if (imageError != null) {
        state = state.copyWith(
          submitting: false,
          eventId: eventId,
          errorMessage: imageError,
          clearSuccessMessage: true,
        );
        return;
      }

      if (publish) {
        await api.publishEvent(eventId);
      }

      state = state.copyWith(
        submitting: false,
        eventId: eventId,
        clearFeaturedImage: true,
        galleryImages: const [],
        successMessage: publish
            ? 'Event published successfully.'
            : 'Draft saved successfully.',
      );
    } catch (e) {
      state = state.copyWith(
        submitting: false,
        errorMessage: _messageFromError(e),
        clearSuccessMessage: true,
      );
    }
  }

  Future<String?> _attachSelectedImagesToEvent({
    required int eventId,
  }) async {
    try {
      final uploadedPaths = <String>{};

      final featured = state.featuredImage;
      if (featured != null) {
        await _uploadAndAttachImage(
          eventId: eventId,
          image: featured,
          isCover: true,
        );
        uploadedPaths.add(featured.localPath);
      }

      for (final image in state.galleryImages) {
        if (uploadedPaths.contains(image.localPath)) {
          continue;
        }

        await _uploadAndAttachImage(
          eventId: eventId,
          image: image,
          isCover: false,
        );
        uploadedPaths.add(image.localPath);
      }

      return null;
    } catch (e) {
      return _messageFromError(e);
    }
  }

  Future<void> _uploadAndAttachImage({
    required int eventId,
    required EventImageUploadItem image,
    required bool isCover,
  }) async {
    final imageUrl = await api.uploadImage(
      image.localPath,
      fileName: image.fileName,
      bytes: image.previewBytes,
    );

    await api.addEventImage(
      eventId: eventId,
      imageUrl: imageUrl,
      isCover: isCover,
    );
  }

  String? _cleanNullable(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _messageFromError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;

      if (data is Map && data['error'] != null) {
        return data['error'].toString();
      }

      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }

      return error.message ?? 'Something went wrong.';
    }

    final text = error.toString();
    if (text.startsWith('Exception: ')) {
      return text.replaceFirst('Exception: ', '');
    }

    return text;
  }
}