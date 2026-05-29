import 'package:dio/dio.dart';

import '../models/activity_log.dart';
import '../models/user_profile.dart';

class ProfileApi {
  final Dio dio;

  ProfileApi(this.dio);

  Future<UserProfile> getMe() async {
    final response = await dio.get('/api/users/me');
    return UserProfile.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<UserProfile> updateMe({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? imageUrl,
    int? cityId,
  }) async {
    final response = await dio.put(
      '/api/users/me',
      data: {
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'imageUrl': imageUrl,
        'cityId': cityId,
      },
    );

    return UserProfile.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await dio.put(
      '/api/users/me/password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  Future<void> revokeAllSessions() async {
    await dio.post('/api/auth/revoke-all');
  }

  Future<List<ActivityLog>> getMyActivityLogs({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await dio.get(
      '/api/users/me/activity-logs',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
      },
    );

    final raw = response.data;

    if (raw is List) {
      return raw
          .map((e) => ActivityLog.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    if (raw is Map && raw['items'] is List) {
      return (raw['items'] as List)
          .map((e) => ActivityLog.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return [];
  }

  Future<List<CitySearchResult>> searchCities(
    String term, {
    int limit = 10,
  }) async {
    final response = await dio.get(
      '/api/cities/search',
      queryParameters: {
        'term': term,
        'limit': limit,
      },
    );

    final raw = response.data;

    if (raw is List) {
      return raw
          .map((e) => CitySearchResult.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    if (raw is Map && raw['items'] is List) {
      return (raw['items'] as List)
          .map((e) => CitySearchResult.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return [];
  }
}