import 'package:dio/dio.dart';

import '../models/event_taxonomy_models.dart';

class EventTaxonomyApi {
  final Dio _dio;

  EventTaxonomyApi(this._dio);

  Future<List<SegmentLookup>> getSegments() async {
    final response = await _dio.get('/api/segments');
    final data = response.data;

    if (data is! List) return const [];

    return data
        .map(
          (e) => SegmentLookup.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  Future<List<GenreLookup>> getGenresForSegment(int segmentId) async {
    final response = await _dio.get('/api/segments/$segmentId/genres');
    final data = response.data;

    if (data is! List) return const [];

    return data
        .map(
          (e) => GenreLookup.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  Future<List<SubGenreLookup>> getSubGenresForGenre(int genreId) async {
    final response = await _dio.get('/api/genres/$genreId/subgenres');
    final data = response.data;

    if (data is! List) return const [];

    return data
        .map(
          (e) => SubGenreLookup.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }
}