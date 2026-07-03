import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../models/user_preference.dart';

class PreferencesApi {
  const PreferencesApi(this.dio);

  final Dio dio;

  Future<List<UserPreference>> getPreferences() async {
    final response = await dio.get(ApiEndpoints.preferences);
    return _parseList(response.data, UserPreference.fromJson);
  }

  Future<List<UserPreference>> getPreferencesForUser(int userId) async {
    final response = await dio.get(ApiEndpoints.preferencesForUser(userId));
    return _parseList(response.data, UserPreference.fromJson);
  }

  Future<void> deletePreference(int prefId) {
    throw UnimplementedError(
      'DELETE /api/preferences/{id} is not exposed by the current backend.',
    );
  }

  Future<UserPreference> upsertPreference({
    int? segmentId,
    int? genreId,
    int? subGenreId,
    required double score,
  }) async {
    throw UnimplementedError(
      'PUT /api/preferences is not exposed by the current backend.',
    );
  }

  List<T> _parseList<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) fromJson,
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

      for (final key in ['items', 'Items', 'data', 'Data', 'results', 'Results']) {
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