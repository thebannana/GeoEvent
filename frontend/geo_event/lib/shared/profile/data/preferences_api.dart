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

    return _parsePaged(
      response.data,
      UserPreference.fromJson,
    );
  }

  Future<PagedResult<UserPreference>> getPreferencesForUser(
    int userId, {
    PreferencesQuery query = const PreferencesQuery(),
  }) async {
    final response = await dio.get(
      ApiEndpoints.preferencesForUser(userId),
      queryParameters: query.toQueryParameters(),
    );

    return _parsePaged(
      response.data,
      UserPreference.fromJson,
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
      return PagedResult<T>.fromJson(
        Map<String, dynamic>.from(raw),
        fromJson,
      );
    }

    throw FormatException(
      'Invalid paged response format.',
    );
  }
}