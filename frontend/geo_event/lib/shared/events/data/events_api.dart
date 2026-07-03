
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/network/api_endpoints.dart';
import '../models/create_event_models.dart';
import '../models/event_taxonomy_models.dart';
import '../models/paged_result.dart';

class EventsApi {
  const EventsApi(this.dio);

  final Dio dio;

  Future<List<SegmentItem>> getSegments() async {
    final response = await dio.get(ApiEndpoints.segments);
    final items = _extractList(response.data);
    return items.map(SegmentItem.fromJson).toList();
  }

  Future<List<GenreItem>> getGenresBySegment(int segmentId) async {
    final response = await dio.get(ApiEndpoints.genresForSegment(segmentId));
    final items = _extractList(response.data);
    return items.map(GenreItem.fromJson).toList();
  }

  Future<List<SubGenreItem>> getSubGenresByGenre(int genreId) async {
    final response = await dio.get(ApiEndpoints.subGenresForGenre(genreId));
    final items = _extractList(response.data);
    return items.map(SubGenreItem.fromJson).toList();
  }

  Future<EventItem> createEvent(CreateEventRequest payload) async {
    final response = await dio.post(
      ApiEndpoints.events,
      data: payload.toJson(),
    );
    return _parseEvent(response.data);
  }

  Future<EventItem> updateEvent(int eventId, CreateEventRequest payload) async {
    final response = await dio.put(
      ApiEndpoints.eventById(eventId),
      data: payload.toJson(),
    );
    return _parseEvent(response.data);
  }

  Future<void> publishEvent(int eventId) async {
    await dio.post(ApiEndpoints.publishEvent(eventId));
  }

Future<void> deleteEventImage({
  required int eventId,
  required int imageId,
}) {
  return dio.delete(
    '${ApiEndpoints.eventImages(eventId)}/$imageId',
    options: Options(
      contentType: Headers.jsonContentType,
      headers: const {
        'Accept': 'application/json',
      },
    ),
  );
}

  Future<void> addEventImage({
    required int eventId,
    required String imageUrl,
    required bool isCover,
  }) async {
    await dio.post(
      ApiEndpoints.eventImages(eventId),
      data: {
        'imageUrl': imageUrl,
        'isCover': isCover,
      },
    );
  }

  Future<String> uploadImage(
    String localPath, {
    String? fileName,
    Uint8List? bytes,
  }) async {
    final resolvedFileName = _resolveFileName(localPath, fileName);
    final contentType = _contentTypeFromFileName(resolvedFileName);

    final MultipartFile multipartFile;
    if (bytes != null) {
      multipartFile = MultipartFile.fromBytes(
        bytes,
        filename: resolvedFileName,
        contentType: contentType,
      );
    } else {
      if (kIsWeb) {
        throw Exception(
          'Image bytes are required for web uploads. Re-pick the image and try again.',
        );
      }

      multipartFile = await MultipartFile.fromFile(
        localPath,
        filename: resolvedFileName,
        contentType: contentType,
      );
    }

    final response = await dio.post(
      ApiEndpoints.uploadImage,
      data: FormData.fromMap({'file': multipartFile}),
      options: Options(contentType: 'multipart/form-data'),
    );

    final data = _asMap(response.data);
    final imageUrl = data['imageUrl']?.toString() ??
        data['url']?.toString() ??
        data['location']?.toString();

    if (imageUrl == null || imageUrl.trim().isEmpty) {
      throw Exception('Image upload succeeded but no image URL was returned.');
    }

    return imageUrl.trim();
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
  }) async {
    final response = await dio.get(
      '${ApiEndpoints.publicEventsBase}/nearby',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'radiusKm': radiusKm,
        'limit': limit,
        'segmentId': ?segmentId,
        'genreId': ?genreId,
        'subGenreId': ?subGenreId,
        if (freeOnly == true) 'maxPrice': 0,
        if (freeOnly != true && minPrice != null) 'minPrice': minPrice,
        if (freeOnly != true && maxPrice != null) 'maxPrice': maxPrice,
        if (todayOnly == true) 'todayOnly': true,
      },
    );

    final items = _extractList(response.data);
    return items.map(EventItem.fromJson).toList();
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
  }) async {
    final response = await dio.get(
      ApiEndpoints.publicEventsBase,
      queryParameters: {
        if (searchTerm != null && searchTerm.trim().isNotEmpty)
          'searchTerm': searchTerm.trim(),
        'page': page,
        'pageSize': pageSize,
        'sortBy': sortBy,
        'sortDescending': sortDescending,
        'segmentId': ?segmentId,
        'genreId': ?genreId,
        'subGenreId': ?subGenreId,
        if (freeOnly == true) 'maxPrice': 0,
        if (freeOnly != true && minPrice != null) 'minPrice': minPrice,
        if (freeOnly != true && maxPrice != null) 'maxPrice': maxPrice,
        if (todayOnly == true) 'todayOnly': true,
      },
    );

    final items = _extractList(response.data);
    return items.map(EventItem.fromJson).toList();
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
  }) async {
    final response = await dio.get(
      ApiEndpoints.publicEventsBase,
      queryParameters: {
        if (searchTerm != null && searchTerm.trim().isNotEmpty)
          'searchTerm': searchTerm.trim(),
        'page': page,
        'pageSize': pageSize,
        'sortBy': sortBy,
        'sortDescending': sortDescending,
        'segmentId': ?segmentId,
        'genreId': ?genreId,
        'subGenreId': ?subGenreId,
      },
    );

    final raw = response.data;
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      if (map.containsKey('items') || map.containsKey('Items')) {
        return PagedResult<EventItem>.fromJson(map, EventItem.fromJson);
      }
    }

    final items = _extractList(raw);
    return PagedResult<EventItem>(
      items: items.map(EventItem.fromJson).toList(),
      totalCount: items.length,
      page: page,
      pageSize: pageSize,
      totalPages: 1,
      hasNextPage: false,
      hasPreviousPage: page > 1,
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
  }) async {
    final result = await searchEventsPaged(
      searchTerm: searchTerm,
      page: page,
      pageSize: pageSize,
      sortBy: sortBy,
      sortDescending: sortDescending,
      segmentId: segmentId,
      genreId: genreId,
      subGenreId: subGenreId,
    );

    return result.items;
  }

  Future<EventItem> getEventById(int eventId) async {
    final response = await dio.get(ApiEndpoints.publicEventById(eventId));
    return _parseEvent(response.data);
  }

  EventItem _parseEvent(dynamic raw) {
    return EventItem.fromJson(_asMap(raw));
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }

    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }

    throw Exception('Invalid response format.');
  }

  List<Map<String, dynamic>> _extractList(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);

      for (final key in [
        'items',
        'Items',
        'data',
        'Data',
        'results',
        'Results',
        'segments',
        'Segments',
        'genres',
        'Genres',
        'subGenres',
        'SubGenres',
      ]) {
        final value = map[key];
        if (value is List) {
          return value
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
    }

    return const [];
  }

  String _resolveFileName(String localPath, String? fileName) {
    final trimmed = fileName?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }

    final normalized = localPath.replaceAll('\\', '/');
    final parts = normalized.split('/');
    final resolved = parts.isNotEmpty ? parts.last.trim() : '';

    return resolved.isEmpty ? 'image.jpg' : resolved;
  }

  MediaType _contentTypeFromFileName(String fileName) {
    final lower = fileName.toLowerCase();

    if (lower.endsWith('.png')) {
      return MediaType('image', 'png');
    }
    if (lower.endsWith('.webp')) {
      return MediaType('image', 'webp');
    }
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }

    throw Exception('Only JPG, PNG, and WEBP images are allowed.');
  }
}