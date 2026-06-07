import 'package:dio/dio.dart';

import '../models/user_preference.dart';

class PreferencesApi {
  final Dio _dio;

  PreferencesApi(this._dio);

  Future<List<UserPreference>> getPreferences() async {
    final response = await _dio.get('/api/preferences');
    final data = response.data;

    if (data is! List) return const [];

    return data
        .map((e) => UserPreference.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<UserPreference> upsertPreference({
    int? segmentId,
    int? genreId,
    required double score,
  }) async {
    final response = await _dio.put(
      '/api/preferences',
      data: {
        'segmentId': ?segmentId,
        'genreId': ?genreId,
        'score': score,
      },
    );

    return UserPreference.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> deletePreference(int prefId) async {
    await _dio.delete('/api/preferences/$prefId');
  }
}