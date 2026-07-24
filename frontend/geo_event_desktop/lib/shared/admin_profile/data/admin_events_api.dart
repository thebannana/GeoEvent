import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/auth_interceptor.dart';
import '../models/admin_event.dart';
import '../models/paged_response.dart';

class AdminEventsApi {
  const AdminEventsApi(this.dio);

  final Dio dio;

  Future<PagedResponse<AdminEvent>> getEvents({
    int page = 1,
    int pageSize = 10,
    String? searchTerm,
    String? status,
    int? organizerId,
    int? segmentId,
    int? genreId,
    int? subGenreId,
    double? minPrice,
    double? maxPrice,
    DateTime? fromDate,
    DateTime? toDate,
    bool? isFeatured,
    bool? canViewReservations,
    String? sortBy,
    bool? sortDescending,
  }) async {
    final response = await dio.get(
      ApiEndpoints.adminEvents,
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (_normalizeNullableString(searchTerm) != null)
          'searchTerm': _normalizeNullableString(searchTerm),
        if (_normalizeNullableString(status) != null)
          'status': _normalizeNullableString(status),
        if (organizerId != null) 'organizerId': organizerId,
        if (segmentId != null) 'segmentId': segmentId,
        if (genreId != null) 'genreId': genreId,
        if (subGenreId != null) 'subGenreId': subGenreId,
        if (minPrice != null) 'minPrice': minPrice,
        if (maxPrice != null) 'maxPrice': maxPrice,
        if (fromDate != null) 'fromDate': fromDate.toUtc().toIso8601String(),
        if (toDate != null) 'toDate': toDate.toUtc().toIso8601String(),
        if (isFeatured != null) 'isFeatured': isFeatured,
        if (canViewReservations != null)
          'canViewReservations': canViewReservations,
        if (_normalizeNullableString(sortBy) != null)
          'sortBy': _normalizeNullableString(sortBy),
        if (sortDescending != null) 'sortDescending': sortDescending,
      },
      options: Options(
        extra: const {
          AuthInterceptor.allowRefreshKey: true,
        },
      ),
    );

    return PagedResponse<AdminEvent>.fromJson(
      _asMap(
        response.data,
        fallbackMessage: 'Invalid admin events response.',
      ),
      AdminEvent.fromJson,
    );
  }

  Future<AdminEvent> getEventById(int eventId) async {
    final response = await dio.get(
      ApiEndpoints.adminEvent(eventId),
      options: Options(
        extra: const {
          AuthInterceptor.allowRefreshKey: true,
        },
      ),
    );

    return AdminEvent.fromJson(
      _asMap(
        response.data,
        fallbackMessage: 'Invalid admin event response.',
      ),
    );
  }

  Future<AdminEvent> updateEvent({
    required int eventId,
    int? segmentId,
    int? genreId,
    int? subGenreId,
    String? title,
    String? description,
    double? latitude,
    double? longitude,
    DateTime? startDateTime,
    DateTime? endDateTime,
    int? capacity,
    double? price,
    bool? isFeatured,
    String? tags,
    String? accessibilityInfo,
    String? promoterName,
    String? locale,
  }) async {
    final response = await dio.put(
      ApiEndpoints.adminEvent(eventId),
      data: _buildUpdatePayload(
        segmentId: segmentId,
        genreId: genreId,
        subGenreId: subGenreId,
        title: title,
        description: description,
        latitude: latitude,
        longitude: longitude,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        capacity: capacity,
        price: price,
        isFeatured: isFeatured,
        tags: tags,
        accessibilityInfo: accessibilityInfo,
        promoterName: promoterName,
        locale: locale,
      ),
      options: Options(
        contentType: Headers.jsonContentType,
        headers: const {'Accept': 'application/json'},
        extra: const {
          AuthInterceptor.allowRefreshKey: true,
        },
      ),
    );

    return AdminEvent.fromJson(
      _asMap(
        response.data,
        fallbackMessage: 'Invalid admin event update response.',
      ),
    );
  }

  Future<void> deleteEvent(int eventId) async {
    await dio.delete(
      ApiEndpoints.adminEvent(eventId),
      options: Options(
        extra: const {
          AuthInterceptor.allowRefreshKey: true,
        },
      ),
    );
  }

  Future<EventReservationSummary> getEventReservationSummary(int eventId) async {
    final response = await dio.get(
      ApiEndpoints.eventReservationSummary(eventId),
      options: Options(
        extra: const {
          AuthInterceptor.allowRefreshKey: true,
        },
      ),
    );

    return EventReservationSummary.fromJson(
      _asMap(
        response.data,
        fallbackMessage: 'Invalid event reservation summary response.',
      ),
    );
  }

  Future<PagedResponse<ManageableEventAttendeePreview>>
      getManageableEventAttendees({
    required int eventId,
    int page = 1,
    int pageSize = 20,
    String? searchTerm,
  }) async {
    final response = await dio.get(
      ApiEndpoints.manageableEventAttendees(eventId),
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (_normalizeNullableString(searchTerm) != null)
          'searchTerm': _normalizeNullableString(searchTerm),
      },
      options: Options(
        extra: const {
          AuthInterceptor.allowRefreshKey: true,
        },
      ),
    );

    return PagedResponse<ManageableEventAttendeePreview>.fromJson(
      _asMap(
        response.data,
        fallbackMessage: 'Invalid manageable attendees response.',
      ),
      ManageableEventAttendeePreview.fromJson,
    );
  }

  Future<void> removeAttendee(
    int eventId,
    int reservationId, {
    String? reason,
  }) async {
    await dio.patch(
      ApiEndpoints.removeEventReservation(eventId, reservationId),
      data: _normalizeNullableString(reason) == null
          ? null
          : {'reason': _normalizeNullableString(reason)},
      options: Options(
        headers: const {'Accept': 'application/json'},
        extra: const {
          AuthInterceptor.allowRefreshKey: true,
        },
      ),
    );
  }

  Future<void> deleteEventImage({
    required int eventId,
    required int imageId,
  }) async {
    await dio.delete(
      ApiEndpoints.adminEventImage(eventId, imageId),
      options: Options(
        contentType: Headers.jsonContentType,
        headers: const {'Accept': 'application/json'},
        extra: const {
          AuthInterceptor.allowRefreshKey: true,
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
      options: Options(
        contentType: Headers.jsonContentType,
        headers: const {'Accept': 'application/json'},
        extra: const {
          AuthInterceptor.allowRefreshKey: true,
        },
      ),
    );
  }

Future<PagedResponse<AdminComment>> getEventComments({
  required int eventId,
  int page = 1,
  int pageSize = 20,
}) async {
  final response = await dio.get(
    ApiEndpoints.commentsByEvent(eventId),
    queryParameters: {
      'page': page,
      'pageSize': pageSize,
    },
    options: Options(
      headers: const {'Accept': 'application/json'},
      extra: const {AuthInterceptor.allowRefreshKey: true},
    ),
  );

  return PagedResponse<AdminComment>.fromJson(
    _asMap(response.data, fallbackMessage: 'Invalid event comments response.'),
    AdminComment.fromJson,
  );
}

Future<PagedResponse<AdminComment>> getCommentReplies({
  required int commentId,
  int page = 1,
  int pageSize = 20,
}) async {
  final response = await dio.get(
    ApiEndpoints.commentReplies(commentId),
    queryParameters: {
      'page': page,
      'pageSize': pageSize,
    },
    options: Options(
      headers: const {'Accept': 'application/json'},
      extra: const {AuthInterceptor.allowRefreshKey: true},
    ),
  );

  return PagedResponse<AdminComment>.fromJson(
    _asMap(response.data, fallbackMessage: 'Invalid comment replies response.'),
    AdminComment.fromJson,
  );
}


Future<AdminComment> updateComment({
  required int commentId,
  required String content,
}) async {
  final response = await dio.put(
    ApiEndpoints.adminCommentById(commentId),
    data: {
      'content': content.trim(),
    },
    options: Options(
      contentType: Headers.jsonContentType,
      headers: const {'Accept': 'application/json'},
      extra: const {AuthInterceptor.allowRefreshKey: true},
    ),
  );

  return AdminComment.fromJson(
    _asMap(response.data, fallbackMessage: 'Invalid admin comment update response.'),
  );
}

Future<void> deleteComment({
  required int commentId,
}) async {
  await dio.delete(
    ApiEndpoints.adminCommentById(commentId),
    options: Options(
      headers: const {'Accept': 'application/json'},
      extra: const {AuthInterceptor.allowRefreshKey: true},
    ),
  );
}

  Future<List<String>> uploadEventImages(
    List<String> filePaths, {
    List<String?>? fileNames,
    List<Uint8List?>? bytesList,
  }) async {
    final normalizedPaths = filePaths
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);

    if (normalizedPaths.isEmpty) {
      return const <String>[];
    }

    if (fileNames != null && fileNames.length != normalizedPaths.length) {
      throw ArgumentError('fileNames length must match filePaths length.');
    }

    if (bytesList != null && bytesList.length != normalizedPaths.length) {
      throw ArgumentError('bytesList length must match filePaths length.');
    }

    final uploadedUrls = <String>[];

    for (var i = 0; i < normalizedPaths.length; i++) {
      final filePath = normalizedPaths[i];
      final providedName = fileNames?[i];
      final providedBytes = bytesList?[i];

      final sourceBytes = providedBytes ??
          (kIsWeb ? null : await File(filePath).readAsBytes());

      if (sourceBytes == null || sourceBytes.isEmpty) {
        throw Exception(
          'Image bytes are required for web uploads. Re-pick the image and try again.',
        );
      }

      final detectedContentType = _contentTypeFromImageBytes(sourceBytes);
      final resolvedFileName = _normalizedFileNameForContentType(
        _resolveFileName(filePath, providedName),
        detectedContentType,
      );

      final formData = FormData();
      formData.files.add(
        MapEntry(
          'file',
          MultipartFile.fromBytes(
            sourceBytes,
            filename: resolvedFileName,
            contentType: detectedContentType,
          ),
        ),
      );

      final response = await dio.post(
        ApiEndpoints.uploadImage,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: const {'Accept': 'application/json'},
          extra: const {
            AuthInterceptor.allowRefreshKey: true,
          },
        ),
      );

      final map = _asMap(
        response.data,
        fallbackMessage: 'Event image upload returned an invalid response.',
      );

      final singleUrl = _normalizeNullableString(
        map['imageUrl'] ?? map['url'] ?? map['location'],
      );

      if (singleUrl == null) {
        throw const FormatException(
          'Event image upload returned an invalid response.',
        );
      }

      uploadedUrls.add(singleUrl);
    }

    return uploadedUrls;
  }

  Future<String> uploadEventImage(
    String filePath, {
    String? fileName,
    Uint8List? bytes,
  }) async {
    final urls = await uploadEventImages(
      [filePath],
      fileNames: [fileName],
      bytesList: [bytes],
    );

    if (urls.isEmpty) {
      throw const FormatException(
        'Event image upload returned an invalid response.',
      );
    }

    return urls.first;
  }

  Map<String, dynamic> _buildUpdatePayload({
    int? segmentId,
    int? genreId,
    int? subGenreId,
    String? title,
    String? description,
    double? latitude,
    double? longitude,
    DateTime? startDateTime,
    DateTime? endDateTime,
    int? capacity,
    double? price,
    bool? isFeatured,
    String? tags,
    String? accessibilityInfo,
    String? promoterName,
    String? locale,
  }) {
    final data = <String, dynamic>{
      'segmentId': segmentId,
      'genreId': genreId,
      'subGenreId': subGenreId,
      'title': _normalizeNullableString(title),
      'description': _normalizeNullableString(description),
      'latitude': latitude,
      'longitude': longitude,
      'startDateTime': startDateTime?.toUtc().toIso8601String(),
      'endDateTime': endDateTime?.toUtc().toIso8601String(),
      'capacity': capacity,
      'price': price,
      'isFeatured': isFeatured,
      'tags': _normalizeNullableString(tags),
      'accessibilityInfo': _normalizeNullableString(accessibilityInfo),
      'promoterName': _normalizeNullableString(promoterName),
      'locale': _normalizeNullableString(locale),
    };

    data.removeWhere((key, value) => value == null);
    return data;
  }

  Map<String, dynamic> _asMap(
    dynamic raw, {
    required String fallbackMessage,
  }) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw FormatException(fallbackMessage);
  }

  String? _normalizeNullableString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  String _resolveFileName(String localPath, String? fileName) {
    final trimmed = fileName?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;

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