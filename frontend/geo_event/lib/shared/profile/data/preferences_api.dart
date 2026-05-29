import 'package:dio/dio.dart';

import '../models/user_preference.dart';

class PreferencesApi {
  final Dio _dio;
  PreferencesApi(this._dio);

  Future<List<UserPreference>> getPreferences() async {
    final response = await _dio.get('/api/preferences');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => UserPreference.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<UserPreference> upsertPreference({
    int? segmentId,
    int? genreId,
    required double score,
  }) async {
    final response = await _dio.put('/api/preferences', data: {
      if (segmentId != null) 'segmentId': segmentId,
      if (genreId != null) 'genreId': genreId,
      'score': score,
    });
    return UserPreference.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deletePreference(int prefId) async {
    await _dio.delete('/api/preferences/$prefId');
  }
}