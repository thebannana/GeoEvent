import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/public_user_profile.dart';

final publicUsersApiProvider = Provider<PublicUsersApi>((ref) {
  return PublicUsersApi(ref.watch(authorizedDioProvider));
});

class PublicUsersApi {
  const PublicUsersApi(this._dio);

  final Dio _dio;

  Future<PublicUserProfileDto> getPublicProfile(int userId) async {
    final response = await _dio.get(ApiEndpoints.publicUser(userId));

    final raw = response.data;
    if (raw is Map<String, dynamic>) {
      return PublicUserProfileDto.fromJson(raw);
    }
    if (raw is Map) {
      return PublicUserProfileDto.fromJson(Map<String, dynamic>.from(raw));
    }

    throw const FormatException('Public profile response was empty.');
  }

  Future<Map<int, PublicUserProfileDto>> getPublicProfiles(List<int> ids) async {
    final normalizedIds = ids.toSet().toList()..sort();

    if (normalizedIds.isEmpty) return const {};

    final response = await _dio.get<List<dynamic>>(
      ApiEndpoints.publicUsers,
      queryParameters: {'ids': normalizedIds},
      options: Options(listFormat: ListFormat.multi),
    );

    final raw = response.data ?? const <dynamic>[];

    final items = raw
        .whereType<Map>()
        .map((item) => PublicUserProfileDto.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    return {for (final item in items) item.userId: item};
  }
}