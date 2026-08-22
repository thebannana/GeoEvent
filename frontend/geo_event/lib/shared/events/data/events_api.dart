import 'dart:io';
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
    final sourceBytes =
        bytes ?? (kIsWeb ? null : await File(localPath).readAsBytes());

    if (sourceBytes == null) {
      throw Exception(
        'Image bytes are required for web uploads. Re-pick the image and try again.',
      );
    }

    final detectedContentType = _contentTypeFromImageBytes(sourceBytes);
    final resolvedFileName = _normalizedFileNameForContentType(
      _resolveFileName(localPath, fileName),
      detectedContentType,
    );

    final multipartFile = MultipartFile.fromBytes(
      sourceBytes,
      filename: resolvedFileName,
      contentType: detectedContentType,
    );

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
  bool usePreferences = false,
}) async {
  final response = await dio.get(
    '${ApiEndpoints.publicEventsBase}/nearby',
    queryParameters: {
      'latitude': latitude,
      'longitude': longitude,
      'radiusKm': radiusKm,
      'limit': limit,
      if (segmentId != null)
        'segmentId': segmentId,
      if (genreId != null)
        'genreId': genreId,
      if (subGenreId != null)
        'subGenreId': subGenreId,
      if (freeOnly == true)
        'maxPrice': 0,
      if (freeOnly != true &&
          minPrice != null)
        'minPrice': minPrice,
      if (freeOnly != true &&
          maxPrice != null)
        'maxPrice': maxPrice,
      if (todayOnly == true)
        'todayOnly': true,
      if (usePreferences)
        'usePreferences': true,
    },
  );

  final items = _extractList(response.data);

  return items
      .map(EventItem.fromJson)
      .toList();
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
  bool usePreferences = false,
}) async {
  final response = await dio.get(
    ApiEndpoints.publicEventsBase,
    queryParameters: {
      if (searchTerm != null &&
          searchTerm.trim().isNotEmpty)
        'searchTerm': searchTerm.trim(),
      'page': page,
      'pageSize': pageSize,
      'sortBy': sortBy,
      'sortDescending': sortDescending,
      if (segmentId != null)
        'segmentId': segmentId,
      if (genreId != null)
        'genreId': genreId,
      if (subGenreId != null)
        'subGenreId': subGenreId,
      if (freeOnly == true)
        'maxPrice': 0,
      if (freeOnly != true &&
          minPrice != null)
        'minPrice': minPrice,
      if (freeOnly != true &&
          maxPrice != null)
        'maxPrice': maxPrice,
      if (todayOnly == true)
        'todayOnly': true,
      if (usePreferences)
        'usePreferences': true,
    },
  );

  final items = _extractList(response.data);

  return items
      .map(EventItem.fromJson)
      .toList();
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
  bool usePreferences = false,
  double? latitude,
  double? longitude,
}) async {
  final response = await dio.get(
    ApiEndpoints.publicEventsBase,
    queryParameters: {
      if (searchTerm != null &&
          searchTerm.trim().isNotEmpty)
        'searchTerm': searchTerm.trim(),
      'page': page,
      'pageSize': pageSize,
      'sortBy': sortBy,
      'sortDescending': sortDescending,
      if (segmentId != null)
        'segmentId': segmentId,
      if (genreId != null)
        'genreId': genreId,
      if (subGenreId != null)
        'subGenreId': subGenreId,
      if (usePreferences)
        'usePreferences': true,
      if (latitude != null)
        'latitude': latitude,
      if (longitude != null)
        'longitude': longitude,
    },
  );

  final raw = response.data;

  if (raw is Map) {
    final map = Map<String, dynamic>.from(raw);

    if (map.containsKey('items') ||
        map.containsKey('Items')) {
      return PagedResult<EventItem>.fromJson(
        map,
        EventItem.fromJson,
      );
    }
  }

  final items = _extractList(raw);

  return PagedResult<EventItem>(
    items: items
        .map(EventItem.fromJson)
        .toList(),
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
  bool usePreferences = false,
  double? latitude,
  double? longitude,
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
    usePreferences: usePreferences,
    latitude: latitude,
    longitude: longitude,
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

  MediaType _contentTypeFromImageBytes(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return MediaType('image', 'jpeg');
    }

    if (bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return MediaType('image', 'png');
    }

    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return MediaType('image', 'webp');
    }

    throw Exception('Only JPG, PNG, and WEBP images are allowed.');
  }

  String _normalizedFileNameForContentType(
    String fileName,
    MediaType contentType,
  ) {
    final lower = fileName.toLowerCase();

    if (contentType.subtype == 'jpeg' &&
        (lower.endsWith('.jpg') || lower.endsWith('.jpeg'))) {
      return fileName;
    }

    if (contentType.subtype == 'png' && lower.endsWith('.png')) {
      return fileName;
    }

    if (contentType.subtype == 'webp' && lower.endsWith('.webp')) {
      return fileName;
    }

    final baseName = fileName.contains('.')
        ? fileName.substring(0, fileName.lastIndexOf('.'))
        : fileName;

    final safeBaseName = baseName.trim().isEmpty ? 'image' : baseName.trim();

    final extension = switch (contentType.subtype) {
      'jpeg' => '.jpg',
      'png' => '.png',
      'webp' => '.webp',
      _ => throw Exception('Unsupported image type.'),
    };

    return '$safeBaseName$extension';
  }
}