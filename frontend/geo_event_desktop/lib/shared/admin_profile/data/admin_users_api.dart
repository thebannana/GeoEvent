import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/auth_interceptor.dart';
import '../models/paged_response.dart';
import '../models/user_profile.dart';

class AdminUsersApi {
  const AdminUsersApi(this.dio);

  final Dio dio;

  Future<PagedResponse<UserProfile>> getUsers({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? role,
    bool? isBanned,
  }) async {
    final response = await dio.get(
      ApiEndpoints.usersBase,
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (_normalizeNullableString(search) != null)
          'search': _normalizeNullableString(search),
        if (_normalizeNullableString(role) != null)
          'role': _normalizeNullableString(role),
        'isBanned': ?isBanned,
      },
      options: Options(
        extra: const {
          AuthInterceptor.allowRefreshKey: true,
        },
      ),
    );

    return PagedResponse<UserProfile>.fromJson(
      _asMap(
        response.data,
        fallbackMessage: 'Invalid users response.',
      ),
      UserProfile.fromJson,
    );
  }

Future<AdminUserProfileDetails> getUserProfileDetails(int userId) async {
  final response = await dio.get(
    ApiEndpoints.adminUserProfile(userId),
    options: Options(
      extra: const {
        AuthInterceptor.allowRefreshKey: true,
      },
    ),
  );

  return AdminUserProfileDetails.fromJson(
    _asMap(
      response.data,
      fallbackMessage: 'Invalid admin user profile response.',
    ),
  );
}

  Future<UserProfile> updateUser({
    required int userId,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? imageUrl,
    String? role,
  }) async {
    final response = await dio.put(
      ApiEndpoints.adminUser(userId),
      data: {
        ..._buildUpdatePayload(
          username: username,
          email: email,
          firstName: firstName,
          lastName: lastName,
          phoneNumber: phoneNumber,
          imageUrl: imageUrl,
        ),
        if (_normalizeNullableString(role) != null)
          'role': _normalizeNullableString(role),
      },
      options: Options(
        contentType: Headers.jsonContentType,
        headers: const {'Accept': 'application/json'},
        extra: const {
          AuthInterceptor.allowRefreshKey: true,
        },
      ),
    );

    return UserProfile.fromJson(
      _asMap(
        response.data,
        fallbackMessage: 'Invalid admin update response.',
      ),
    );
  }

  Future<String> uploadProfileImage(String filePath) async {
  final fileName = filePath.split(RegExp(r'[\\/]')).last;

  final formData = FormData.fromMap({
    'file': await MultipartFile.fromFile(
      filePath,
      filename: fileName,
    ),
  });

  final response = await dio.post(
    ApiEndpoints.uploadImage,
    data: formData,
    options: Options(
      contentType: 'multipart/form-data',
      headers: const {'Accept': 'application/json'},
      extra: const {
        AuthInterceptor.allowRefreshKey: true,
      },
    ),
  );

  final map = _asMap(
    response.data,
    fallbackMessage: 'Profile image upload returned an invalid response.',
  );

  final imageUrl = _normalizeNullableString(
    map['imageUrl'] ?? map['url'] ?? map['location'],
  );

  if (imageUrl == null) {
    throw const FormatException(
      'Profile image upload returned an invalid response.',
    );
  }

  return imageUrl;
}

  Future<void> deleteUser(int userId) async {
    await dio.delete(
      ApiEndpoints.adminUser(userId),
      options: Options(
        extra: const {
          AuthInterceptor.allowRefreshKey: true,
        },
      ),
    );
  }

  Future<void> banUser(int userId) async {
    await dio.post(
      ApiEndpoints.banUser(userId),
      options: Options(
        extra: const {
          AuthInterceptor.allowRefreshKey: true,
        },
      ),
    );
  }

  Future<void> unbanUser(int userId) async {
    await dio.post(
      ApiEndpoints.unbanUser(userId),
      options: Options(
        extra: const {
          AuthInterceptor.allowRefreshKey: true,
        },
      ),
    );
  }

  Map<String, dynamic> _buildUpdatePayload({
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? imageUrl,
  }) {
    final data = <String, dynamic>{
      'username': _normalizeNullableString(username),
      'email': _normalizeNullableString(email),
      'firstName': _normalizeNullableString(firstName),
      'lastName': _normalizeNullableString(lastName),
      'phoneNumber': _normalizeNullableString(phoneNumber),
      'imageUrl': _normalizeNullableString(imageUrl),
    };

    data.removeWhere((key, value) => value == null);
    return data;
  }

  Map<String, dynamic> _asMap(
    dynamic raw, {
    required String fallbackMessage,
  }) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw FormatException(fallbackMessage);
  }

  String? _normalizeNullableString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}