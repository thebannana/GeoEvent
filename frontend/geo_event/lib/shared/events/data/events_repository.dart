import 'dart:typed_data';

import '../models/create_event_models.dart';
import '../models/event_taxonomy_models.dart';
import '../models/paged_result.dart';
import 'events_api.dart';

class EventsRepository {
  const EventsRepository(this.api);

  final EventsApi api;

  Future<List<SegmentItem>> getSegments() => api.getSegments();

  Future<List<GenreItem>> getGenresBySegment(int segmentId) {
    return api.getGenresBySegment(segmentId);
  }

  Future<List<SubGenreItem>> getSubGenresByGenre(int genreId) {
    return api.getSubGenresByGenre(genreId);
  }

  Future<EventItem> createEvent(CreateEventRequest payload) {
    return api.createEvent(payload);
  }

  Future<EventItem> updateEvent(int eventId, CreateEventRequest payload) {
    return api.updateEvent(eventId, payload);
  }

  Future<void> publishEvent(int eventId) {
    return api.publishEvent(eventId);
  }

  Future<void> deleteEventImage({
  required int eventId,
  required int imageId,
}) {
  return api.deleteEventImage(
    eventId: eventId,
    imageId: imageId,
  );
}

  Future<void> addEventImage({
    required int eventId,
    required String imageUrl,
    required bool isCover,
  }) {
    return api.addEventImage(
      eventId: eventId,
      imageUrl: imageUrl,
      isCover: isCover,
    );
  }

  Future<String> uploadImage(
    String localPath, {
    String? fileName,
    Uint8List? bytes,
  }) {
    return api.uploadImage(
      localPath,
      fileName: fileName,
      bytes: bytes,
    );
  }

  Future<List<EventItem>> getNearbyEvents({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
    int limit = 100,
    int? segmentId,
    int? genreId,
    int? subGenreId,
    double? minPrice,
    double? maxPrice,
    bool? freeOnly,
    bool? todayOnly,
  }) {
    return api.getNearbyEvents(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      limit: limit,
      segmentId: segmentId,
      genreId: genreId,
      subGenreId: subGenreId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      freeOnly: freeOnly,
      todayOnly: todayOnly,
    );
  }

  Future<PagedResult<EventItem>> searchEventsPaged({
    String? searchTerm,
    int page = 1,
    int pageSize = 20,
    String sortBy = 'StartDateTime',
    bool sortDescending = false,
    int? segmentId,
    int? genreId,
    int? subGenreId,
  }) {
    return api.searchEventsPaged(
      searchTerm: searchTerm,
      page: page,
      pageSize: pageSize,
      sortBy: sortBy,
      sortDescending: sortDescending,
      segmentId: segmentId,
      genreId: genreId,
      subGenreId: subGenreId,
    );
  }

  Future<List<EventItem>> searchEvents({
    String? searchTerm,
    int page = 1,
    int pageSize = 20,
    String sortBy = 'StartDateTime',
    bool sortDescending = false,
    int? segmentId,
    int? genreId,
    int? subGenreId,
  }) {
    return api.searchEvents(
      searchTerm: searchTerm,
      page: page,
      pageSize: pageSize,
      sortBy: sortBy,
      sortDescending: sortDescending,
      segmentId: segmentId,
      genreId: genreId,
      subGenreId: subGenreId,
    );
  }

  Future<List<EventItem>> getGlobalEvents({
    String? searchTerm,
    int page = 1,
    int pageSize = 100,
    String sortBy = 'StartDateTime',
    bool sortDescending = false,
    int? segmentId,
    int? genreId,
    int? subGenreId,
    double? minPrice,
    double? maxPrice,
    bool? freeOnly,
    bool? todayOnly,
  }) {
    return api.getGlobalEvents(
      searchTerm: searchTerm,
      page: page,
      pageSize: pageSize,
      sortBy: sortBy,
      sortDescending: sortDescending,
      segmentId: segmentId,
      genreId: genreId,
      subGenreId: subGenreId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      freeOnly: freeOnly,
      todayOnly: todayOnly,
    );
  }

  Future<EventItem> getEventById(int eventId) {
    return api.getEventById(eventId);
  }
}