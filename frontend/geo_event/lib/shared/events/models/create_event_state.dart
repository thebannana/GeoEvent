import 'create_event_models.dart';
import 'event_taxonomy_models.dart';

class CreateEventState {
  final bool loadingInitial;
  final bool genresLoading;
  final bool subGenresLoading;
  final bool submitting;

  final List<SegmentItem> segments;
  final List<GenreItem> genres;
  final List<SubGenreItem> subGenres;

  final int? segmentId;
  final int? genreId;
  final int? subGenreId;

  final bool clearGenreId;
  final bool clearSubGenreId;

  final bool isFree;

  final MapboxPlace? selectedLocation;
  final bool clearSelectedLocation;

  final EventImageUploadItem? featuredImage;
  final bool clearFeaturedImage;
  final List<EventImageUploadItem> galleryImages;

  final int? eventId;

  final String? errorMessage;
  final String? successMessage;

  const CreateEventState({
    this.loadingInitial = false,
    this.genresLoading = false,
    this.subGenresLoading = false,
    this.submitting = false,
    this.segments = const [],
    this.genres = const [],
    this.subGenres = const [],
    this.segmentId,
    this.genreId,
    this.subGenreId,
    this.clearGenreId = false,
    this.clearSubGenreId = false,
    this.isFree = false,
    this.selectedLocation,
    this.clearSelectedLocation = false,
    this.featuredImage,
    this.clearFeaturedImage = false,
    this.galleryImages = const [],
    this.eventId,
    this.errorMessage,
    this.successMessage,
  });

  CreateEventState copyWith({
    bool? loadingInitial,
    bool? genresLoading,
    bool? subGenresLoading,
    bool? submitting,
    List<SegmentItem>? segments,
    List<GenreItem>? genres,
    List<SubGenreItem>? subGenres,
    int? segmentId,
    int? genreId,
    int? subGenreId,
    bool clearSegmentId = false,
    bool clearGenreId = false,
    bool clearSubGenreId = false,
    bool? isFree,
    MapboxPlace? selectedLocation,
    bool clearSelectedLocation = false,
    EventImageUploadItem? featuredImage,
    bool clearFeaturedImage = false,
    List<EventImageUploadItem>? galleryImages,
    int? eventId,
    bool clearEventId = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return CreateEventState(
      loadingInitial: loadingInitial ?? this.loadingInitial,
      genresLoading: genresLoading ?? this.genresLoading,
      subGenresLoading: subGenresLoading ?? this.subGenresLoading,
      submitting: submitting ?? this.submitting,
      segments: segments ?? this.segments,
      genres: genres ?? this.genres,
      subGenres: subGenres ?? this.subGenres,
      segmentId: clearSegmentId ? null : (segmentId ?? this.segmentId),
      genreId: clearGenreId ? null : (genreId ?? this.genreId),
      subGenreId: clearSubGenreId ? null : (subGenreId ?? this.subGenreId),
      clearGenreId: clearGenreId,
      clearSubGenreId: clearSubGenreId,
      isFree: isFree ?? this.isFree,
      selectedLocation: clearSelectedLocation
          ? null
          : (selectedLocation ?? this.selectedLocation),
      clearSelectedLocation: clearSelectedLocation,
      featuredImage: clearFeaturedImage
          ? null
          : (featuredImage ?? this.featuredImage),
      clearFeaturedImage: clearFeaturedImage,
      galleryImages: galleryImages ?? this.galleryImages,
      eventId: clearEventId ? null : (eventId ?? this.eventId),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccessMessage
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}