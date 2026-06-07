import 'package:dio/dio.dart';

import '../models/activity_log.dart';
import '../models/user_profile.dart';

class ProfileApi {
  final Dio dio;

  ProfileApi(this.dio);

  Future<UserProfile> getMe() async {
    final response = await dio.get('/api/users/me');
    final raw = response.data;
    if (raw is! Map) {
      throw Exception('Invalid profile response.');
    }
    return UserProfile.fromJson(Map<String, dynamic>.from(raw));
  }

    Future<UserProfile> updateMe({
  String? username,
  String? email,
  String? firstName,
  String? lastName,
  String? phoneNumber,
  String? imageUrl,
}) async {
  final data = <String, dynamic>{
    'username': username,
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'phoneNumber': phoneNumber,
    'imageUrl': imageUrl,
  }..removeWhere((key, value) => value == null);

  final response = await dio.put('/api/users/me', data: data);

  final raw = response.data;
  if (raw is! Map) {
    throw Exception('Invalid profile update response.');
  }

  return UserProfile.fromJson(Map<String, dynamic>.from(raw));
}

  Future<String> uploadProfileImage(String filePath) async {
  final fileName = filePath.split('/').last;

  final formData = FormData.fromMap({
    'file': await MultipartFile.fromFile(filePath, filename: fileName),
  });

  final response = await dio.post(
    '/api/uploads/images',
    data: formData,
  );

  final raw = response.data;

  if (raw is Map) {
    final map = Map<String, dynamic>.from(raw);
    final imageUrl = map['imageUrl']?.toString();
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      return imageUrl.trim();
    }
  }

  throw Exception('Profile image upload returned an invalid response.');
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
    final items = switch (raw) {
      List _ => raw,
      Map _ when raw['items'] is List => raw['items'] as List,
      _ => throw Exception('Invalid activity logs response.'),
    };

    return items
        .map((e) => ActivityLog.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}