import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../models/paged_result.dart';
import '../models/preferences_query.dart';
import '../models/user_preference.dart';

class PreferencesApi {
  const PreferencesApi(this.dio);

  final Dio dio;

  Future<PagedResult<UserPreference>> getPreferences({
    PreferencesQuery query = const PreferencesQuery(),
  }) async {
    final response = await dio.get(
      ApiEndpoints.preferences,
      queryParameters: query.toQueryParameters(),
    );

    return _parsePaged(response.data, UserPreference.fromJson);
  }

  Future<PagedResult<UserPreference>> getPreferencesForUser(
    int userId, {
    PreferencesQuery query = const PreferencesQuery(),
  }) async {
    final response = await dio.get(
      ApiEndpoints.preferencesForUser(userId),
      queryParameters: query.toQueryParameters(),
    );

    return _parsePaged(response.data, UserPreference.fromJson);
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

  PagedResult<T> _parsePaged<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw is Map<String, dynamic>) {
      return PagedResult<T>.fromJson(raw, fromJson);
    }

    if (raw is Map) {
      return PagedResult<T>.fromJson(Map<String, dynamic>.from(raw), fromJson);
    }

    throw Exception('Invalid paged response format.');
  }
}