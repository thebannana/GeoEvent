import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/public_user_profile.dart';

final publicUsersApiProvider = Provider<PublicUsersApi>((ref) {
  return PublicUsersApi(ref.watch(authorizedDioProvider));
});

class PublicUsersApi {
  final Dio _dio;

  const PublicUsersApi(this._dio);

  Future<PublicUserProfileDto> getPublicProfile(int userId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/users/$userId/public',
    );

    final data = response.data;
    if (data == null) {
      throw Exception('Public profile response was empty.');
    }

    return PublicUserProfileDto.fromJson(data);
  }

  Future<Map<int, PublicUserProfileDto>> getPublicProfiles(List<int> ids) async {
    final normalizedIds = ids.toSet().toList()..sort();

    if (normalizedIds.isEmpty) {
      return const {};
    }

    final response = await _dio.get<List<dynamic>>(
      '/api/users/public',
      queryParameters: {
        'ids': normalizedIds,
      },
      options: Options(
        listFormat: ListFormat.multi,
      ),
    );

    final raw = response.data ?? const [];

    final items = raw
        .whereType<Map>()
        .map(
          (e) => PublicUserProfileDto.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();

    return {
      for (final item in items) item.userId: item,
    };
  }
}