import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../models/event_taxonomy_models.dart';

class EventTaxonomyApi {
  const EventTaxonomyApi(this._dio);

  final Dio _dio;

  Future<List<SegmentLookup>> getSegments() async {
    final response = await _dio.get(ApiEndpoints.segments);
    return _parseList(response.data, SegmentLookup.fromJson);
  }

  Future<List<GenreLookup>> getGenresForSegment(int segmentId) async {
    final response = await _dio.get(
      ApiEndpoints.genresForSegment(segmentId),
    );
    return _parseList(response.data, GenreLookup.fromJson);
  }

  Future<List<SubGenreLookup>> getSubGenresForGenre(int genreId) async {
    final response = await _dio.get(
      ApiEndpoints.subGenresForGenre(genreId),
    );
    return _parseList(response.data, SubGenreLookup.fromJson);
  }

  List<T> _parseList<T>(
    dynamic raw,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    if (raw is List) {
      return raw
          .map(_tryMap)
          .whereType<Map<String, dynamic>>()
          .map(fromJson)
          .toList();
    }

    if (raw is Map) {
      final map = raw is Map<String, dynamic>
          ? raw
          : Map<String, dynamic>.from(raw);

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
              .map(_tryMap)
              .whereType<Map<String, dynamic>>()
              .map(fromJson)
              .toList();
        }
      }
    }

    return const [];
  }

  Map<String, dynamic>? _tryMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }

    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }

    return null;
  }
}