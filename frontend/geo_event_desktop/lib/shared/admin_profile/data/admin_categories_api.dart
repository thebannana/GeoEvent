import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/auth_interceptor.dart';
import '../models/categories.dart';
import '../models/paged_response.dart';

class AdminCategoriesApi {
  const AdminCategoriesApi(this.dio);

  final Dio dio;

  Future<List<AdminSegment>> getSegments() async {
    final response = await dio.get(
      ApiEndpoints.segments,
      options: Options(
        extra: const {
          AuthInterceptor.allowRefreshKey: true,
        },
      ),
    );

    final raw = response.data;
    if (raw is! List) {
      throw const FormatException('Invalid segments response.');
    }

    return raw
        .map((item) => AdminSegment.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<PagedResponse<AdminSegment>> getSegmentsPage({
  required int page,
  required int pageSize,
  String? searchTerm,
}) async {
  final response = await dio.get(
    ApiEndpoints.segments,
    queryParameters: {
      'paged': true,
      'page': page,
      'pageSize': pageSize,
      if (searchTerm != null && searchTerm.trim().isNotEmpty)
        'searchTerm': searchTerm.trim(),
    },
    options: Options(
      extra: const {
        AuthInterceptor.allowRefreshKey: true,
      },
    ),
  );

  final raw = response.data;
  if (raw is! Map) {
    throw const FormatException('Invalid paged segments response.');
  }

  return PagedResponse<AdminSegment>.fromJson(
    Map<String, dynamic>.from(raw),
    AdminSegment.fromJson,
  );
}

  Future<PagedResponse<AdminGenre>> getGenresPage({
    required int page,
    required int pageSize,
    String? searchTerm,
  }) async {
    final response = await dio.get(
      ApiEndpoints.genres,
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (searchTerm != null && searchTerm.trim().isNotEmpty)
          'searchTerm': searchTerm.trim(),
      },
      options: Options(
        extra: const {
          AuthInterceptor.allowRefreshKey: true,
        },
      ),
    );

    final raw = response.data;
    if (raw is! Map) {
      throw const FormatException('Invalid paged genres response.');
    }

    return PagedResponse<AdminGenre>.fromJson(
      Map<String, dynamic>.from(raw),
      AdminGenre.fromJson,
    );
  }

  Future<PagedResponse<AdminSubGenre>> getSubGenresPage({
    required int page,
    required int pageSize,
    String? searchTerm,
  }) async {
    final response = await dio.get(
      ApiEndpoints.subGenres,
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (searchTerm != null && searchTerm.trim().isNotEmpty)
          'searchTerm': searchTerm.trim(),
      },
      options: Options(
        extra: const {
          AuthInterceptor.allowRefreshKey: true,
        },
      ),
    );

    final raw = response.data;
    if (raw is! Map) {
      throw const FormatException('Invalid paged subgenres response.');
    }

    return PagedResponse<AdminSubGenre>.fromJson(
      Map<String, dynamic>.from(raw),
      AdminSubGenre.fromJson,
    );
  }

  Future<AdminSegment> createSegment({
    required String name,
    String? iconUrl,
    String? color,
    bool isActive = true,
  }) async {
    final response = await dio.post(
      ApiEndpoints.segments,
      data: {
        'name': name.trim(),
        'iconUrl': iconUrl?.trim().isEmpty == true ? null : iconUrl?.trim(),
        'color': color?.trim().isEmpty == true ? null : color?.trim(),
        'isActive': isActive,
      },
      options: Options(
        contentType: Headers.jsonContentType,
        headers: const {'Accept': 'application/json'},
        extra: const {
          AuthInterceptor.allowRefreshKey: true,
        },
      ),
    );

    return AdminSegment.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<AdminSegment> updateSegment({
    required int segmentId,
    String? name,
    String? iconUrl,
    String? color,
    bool? isActive,
  }) async {
    final response = await dio.put(
      ApiEndpoints.segmentById(segmentId),
      data: {
        if (name != null) 'name': name.trim(),
        if (iconUrl != null) 'iconUrl': iconUrl.trim(),
        if (color != null) 'color': color.trim(),
        'isActive': ?isActive,
      },
      options: Options(
        contentType: Headers.jsonContentType,
        headers: const {'Accept': 'application/json'},
        extra: const {
          AuthInterceptor.allowRefreshKey: true,
        },
      ),
    );

    return AdminSegment.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<AdminGenre> createGenre({
    required int segmentId,
    required String name,
    bool isActive = true,
  }) async {
    final response = await dio.post(
      ApiEndpoints.genres,
      data: {
        'segmentId': segmentId,
        'name': name.trim(),
        'isActive': isActive,
      },
      options: Options(
        contentType: Headers.jsonContentType,
        headers: const {'Accept': 'application/json'},
        extra: const {
          AuthInterceptor.allowRefreshKey: true,
        },
      ),
    );

    return AdminGenre.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<AdminGenre> updateGenre({
    required int genreId,
    int? segmentId,
    String? name,
    bool? isActive,
  }) async {
    final response = await dio.put(
      ApiEndpoints.genreById(genreId),
      data: {
        if (segmentId != null) 'segmentId': segmentId,
        if (name != null) 'name': name.trim(),
        if (isActive != null) 'isActive': isActive,
      },
      options: Options(
        contentType: Headers.jsonContentType,
        headers: const {'Accept': 'application/json'},
        extra: const {
          AuthInterceptor.allowRefreshKey: true,
        },
      ),
    );

    return AdminGenre.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<AdminSubGenre> createSubGenre({
    required int genreId,
    required String name,
    bool isActive = true,
  }) async {
    final response = await dio.post(
      ApiEndpoints.subGenres,
      data: {
        'genreId': genreId,
        'name': name.trim(),
        'isActive': isActive,
      },
      options: Options(
        contentType: Headers.jsonContentType,
        headers: const {'Accept': 'application/json'},
        extra: const {
          AuthInterceptor.allowRefreshKey: true,
        },
      ),
    );

    return AdminSubGenre.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<AdminSubGenre> updateSubGenre({
    required int subGenreId,
    int? genreId,
    String? name,
    bool? isActive,
  }) async {
    final response = await dio.put(
      ApiEndpoints.subGenreById(subGenreId),
      data: {
        if (genreId != null) 'genreId': genreId,
        if (name != null) 'name': name.trim(),
        if (isActive != null) 'isActive': isActive,
      },
      options: Options(
        contentType: Headers.jsonContentType,
        headers: const {'Accept': 'application/json'},
        extra: const {
          AuthInterceptor.allowRefreshKey: true,
        },
      ),
    );

    return AdminSubGenre.fromJson(Map<String, dynamic>.from(response.data as Map));
  }
}