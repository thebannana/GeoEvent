import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';

import '../models/create_event_models.dart';
import '../models/event_taxonomy_models.dart';
import '../models/paged_result.dart';

class EventsApi {
  final Dio dio;

  EventsApi(this.dio);

  Future<List<SegmentItem>> getSegments() async {
    final response = await dio.get('/api/segments');
    final items = _extractList(response.data);

    return items.map(SegmentItem.fromJson).toList();
  }

  Future<List<GenreItem>> getGenresBySegment(int segmentId) async {
    final response = await dio.get('/api/segments/$segmentId/genres');
    final items = _extractList(response.data);

    return items.map(GenreItem.fromJson).toList();
  }

  Future<List<SubGenreItem>> getSubGenresByGenre(int genreId) async {
    final response = await dio.get('/api/genres/$genreId/subgenres');
    final items = _extractList(response.data);

    return items.map(SubGenreItem.fromJson).toList();
  }

  Future<EventItem> createEvent(CreateEventRequest payload) async {
    final body = payload.toJson();
    print('CREATE EVENT REQUEST BODY: $body');

    final response = await dio.post(
      '/api/events',
      data: payload.toJson(),
    );

    return _parseEvent(response.data);
  }

  Future<EventItem> updateEvent(
    int eventId,
    CreateEventRequest payload,
  ) async {
    final response = await dio.put(
      '/api/events/$eventId',
      data: payload.toJson(),
    );

    return _parseEvent(response.data);
  }

  Future<void> publishEvent(int eventId) async {
    await dio.post('/api/events/$eventId/publish');
  }

  Future<void> addEventImage({
    required int eventId,
    required String imageUrl,
    required bool isCover,
  }) async {
    await dio.post(
      '/api/events/$eventId/images',
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
    final resolvedFileName = (fileName == null || fileName.trim().isEmpty)
        ? _fileNameFromPath(localPath)
        : fileName.trim();

    final contentType = _contentTypeFromFileName(resolvedFileName);

    MultipartFile multipartFile;
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

    final formData = FormData.fromMap({
      'file': multipartFile,
    });

    final response = await dio.post(
      '/api/uploads/images',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final data = _asMap(response.data);
    final imageUrl = data['imageUrl']?.toString() ??
        data['url']?.toString() ??
        data['location']?.toString();

    if (imageUrl == null || imageUrl.isEmpty) {
      throw Exception('Image upload succeeded but no image URL was returned.');
    }

    return imageUrl;
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
    '/api/public/events/nearby',
    queryParameters: {
      'latitude': latitude,
      'longitude': longitude,
      'radiusKm': radiusKm,
      'limit': limit,
      if (segmentId != null) 'segmentId': segmentId,
      if (genreId != null) 'genreId': genreId,
      if (subGenreId != null) 'subGenreId': subGenreId,
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
    '/api/public/events',
    queryParameters: {
      if (searchTerm != null && searchTerm.trim().isNotEmpty)
        'searchTerm': searchTerm.trim(),
      'page': page,
      'pageSize': pageSize,
      'sortBy': sortBy,
      'sortDescending': sortDescending,
      if (segmentId != null) 'segmentId': segmentId,
      if (genreId != null) 'genreId': genreId,
      if (subGenreId != null) 'subGenreId': subGenreId,
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
      '/api/public/events',
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
      if (map.containsKey('items')) {
        return PagedResult<EventItem>.fromJson(
          map,
          EventItem.fromJson,
        );
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
    final response = await dio.get('/api/public/events/$eventId');
    return _parseEvent(response.data);
  }

  EventItem _parseEvent(dynamic raw) {
    final data = _asMap(raw);
    return EventItem.fromJson(data);
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
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
        'data',
        'results',
        'segments',
        'genres',
        'subGenres',
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

  String _fileNameFromPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    final parts = normalized.split('/');
    final fileName = parts.isNotEmpty ? parts.last.trim() : '';

    if (fileName.isEmpty) return 'image.jpg';
    return fileName;
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