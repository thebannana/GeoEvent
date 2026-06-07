import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/events/data/events_repository.dart';
import '../../../shared/events/models/create_event_models.dart';
import '../../../shared/events/models/create_event_state.dart';
import '../../../shared/events/models/my_event_response_dto.dart';
import '../../../shared/events/providers/event_providers.dart';

final createEventControllerProvider =
    StateNotifierProvider.autoDispose<CreateEventController, CreateEventState>((ref) {
  return CreateEventController(
    repository: ref.watch(eventsRepositoryProvider),
  );
});

class CreateEventController extends StateNotifier<CreateEventState> {
  final EventsRepository repository;

  CreateEventController({
    required this.repository,
  }) : super(const CreateEventState());

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
      clearSuccessMessage: true,
    );

    if (id == null) {
      state = state.copyWith(genresLoading: false);
      return;
    }

    try {
      final genres = await repository.getGenresBySegment(id);
      state = state.copyWith(
        genresLoading: false,
        genres: genres,
      );
    } catch (e) {
      state = state.copyWith(
        genresLoading: false,
        errorMessage: _messageFromError(e),
        clearSuccessMessage: true,
      );
    }
  }

Future<MapboxPlace?> reverseGeocode({
  required double latitude,
  required double longitude,
  required String accessToken,
}) async {
  final dio = Dio();

  final response = await dio.get<Map<String, dynamic>>(
    'https://api.mapbox.com/search/geocode/v6/reverse',
    queryParameters: {
      'longitude': longitude,
      'latitude': latitude,
      'access_token': accessToken,
      'limit': 1,
      'language': 'en',
    },
  );

  final data = response.data ?? const <String, dynamic>{};
  final features = data['features'];

  if (features is! List || features.isEmpty) return null;

  final item = Map<String, dynamic>.from(features.first as Map);

  return MapboxPlace(
    id: item['id']?.toString() ?? '$longitude,$latitude',
    title: item['properties']?['name']?.toString() ??
        item['name']?.toString() ??
        'Selected location',
    subtitle: item['full_address']?.toString() ??
        item['place_formatted']?.toString() ??
        '',
    latitude: latitude,
    longitude: longitude,
  );
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
      state = state.copyWith(subGenresLoading: false);
      return;
    }

    try {
      final subGenres = await repository.getSubGenresByGenre(id);
      state = state.copyWith(
        subGenresLoading: false,
        subGenres: subGenres,
      );
    } catch (e) {
      state = state.copyWith(
        subGenresLoading: false,
        errorMessage: _messageFromError(e),
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
  final venueTitle = event.isOnline
      ? 'Online event'
      : ((event.venueName?.trim().isNotEmpty ?? false)
          ? event.venueName!.trim()
          : 'Selected location');

  final subtitle = event.isOnline
      ? (event.externalUrl?.trim().isNotEmpty ?? false)
          ? event.externalUrl!.trim()
          : 'Coordinates: ${event.latitude}, ${event.longitude}'
      : '${event.latitude.toStringAsFixed(6)}, ${event.longitude.toStringAsFixed(6)}';

  state = state.copyWith(
    eventId: event.eventId,
    segmentId: event.segmentId,
    genreId: event.genreId,
    subGenreId: event.subGenreId,
    isOnline: event.isOnline,
    isFree: event.price <= 0,
    selectedLocation: MapboxPlace(
      id: event.venueId?.toString() ?? 'event-${event.eventId}',
      title: venueTitle,
      subtitle: subtitle,
      latitude: event.latitude,
      longitude: event.longitude,
    ),
    clearErrorMessage: true,
    clearSuccessMessage: true,
  );
}

  void setOnline(bool value) {
    state = state.copyWith(
      isOnline: value,
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

  void setGalleryImages(List<EventImageUploadItem> images) {
    final unique = <String, EventImageUploadItem>{};
    for (final image in images) {
      unique[image.localPath] = image;
    }

    state = state.copyWith(
      galleryImages: unique.values.toList(),
      clearErrorMessage: true,
      clearSuccessMessage: true,
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

    if (uniqueNewImages.isEmpty) return;

    state = state.copyWith(
      galleryImages: [...state.galleryImages, ...uniqueNewImages],
      clearErrorMessage: true,
      clearSuccessMessage: true,
    );
  }

  void removeGalleryImageAt(int index) {
    if (index < 0 || index >= state.galleryImages.length) return;

    final updated = [...state.galleryImages]..removeAt(index);
    state = state.copyWith(
      galleryImages: updated,
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
      final normalizedPrice = state.isFree ? 0.0 : price;

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

      if (normalizedPrice < 0 || normalizedPrice > 100000) {
        throw Exception('Price must be between 0 and 100000.');
      }

      //if (segmentId == null) {
      //throw Exception('Please select a segment.');
      //}

      //if (genreId == null) {
      //  throw Exception('Please select a genre.');
      //}

      //if (subGenreId == null) {
      //  throw Exception('Please select a subgenre.');
      //}

      //if (!isOnline && venueId == null && cityId == null) {
      //  throw Exception('Please choose a venue or location for an offline event.');
      //}

      //if (isOnline) {
      //  if (cleanExternalUrl == null || cleanExternalUrl.isEmpty) {
      //    throw Exception('Please provide an external URL for an online event.');
      //  }
      //}

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
        price: normalizedPrice,
        isOnline: isOnline,
        tags: cleanTags,
        externalUrl: cleanExternalUrl,
        accessibilityInfo: cleanAccessibilityInfo,
        promoterName: cleanPromoterName,
        locale: cleanLocale,
      );

      final event = state.eventId == null
          ? await repository.createEvent(payload)
          : await repository.updateEvent(state.eventId!, payload);

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
        await repository.publishEvent(eventId);
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