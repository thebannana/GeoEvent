import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/auth_interceptor.dart';
import '../models/user_profile.dart';

class ProfileApi {
  const ProfileApi(this.dio);

  final Dio dio;

  Future<UserProfile> getMe() async {
    final response = await dio.get(
      ApiEndpoints.currentUser,
      options: Options(
        extra: const {
          AuthInterceptor.allowRefreshKey: true,
        },
      ),
    );

    return UserProfile.fromJson(
      asMap(
        response.data,
        fallbackMessage: 'Invalid profile response.',
      ),
    );
  }

  Future<UserProfile> updateMe({
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? imageUrl,
  }) async {
    final response = await dio.put(
      ApiEndpoints.currentUser,
      data: buildUpdatePayload(
        username: username,
        email: email,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        imageUrl: imageUrl,
      ),
      options: Options(
        contentType: Headers.jsonContentType,
        headers: const {'Accept': 'application/json'},
        extra: const {
          AuthInterceptor.allowRefreshKey: true,
        },
      ),
    );

    return UserProfile.fromJson(
      asMap(
        response.data,
        fallbackMessage: 'Invalid profile update response.',
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

    final map = asMap(
      response.data,
      fallbackMessage: 'Profile image upload returned an invalid response.',
    );

    final imageUrl = normalizeNullableString(
      map['imageUrl'] ?? map['url'] ?? map['location'],
    );

    if (imageUrl == null) {
      throw const FormatException(
        'Profile image upload returned an invalid response.',
      );
    }

    return imageUrl;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await dio.put(
      ApiEndpoints.changePassword,
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
      options: Options(
        contentType: Headers.jsonContentType,
        headers: const {'Accept': 'application/json'},
        extra: const {
          AuthInterceptor.allowRefreshKey: false,
        },
      ),
    );
  }

  Map<String, dynamic> buildUpdatePayload({
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? imageUrl,
  }) {
    final data = <String, dynamic>{
      'username': normalizeNullableString(username),
      'email': normalizeNullableString(email),
      'firstName': normalizeNullableString(firstName),
      'lastName': normalizeNullableString(lastName),
      'phoneNumber': normalizeNullableString(phoneNumber),
      'imageUrl': normalizeNullableString(imageUrl),
    };

    data.removeWhere((key, value) => value == null);
    return data;
  }

  Map<String, dynamic> asMap(
    dynamic raw, {
    required String fallbackMessage,
  }) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw FormatException(fallbackMessage);
  }

  String? normalizeNullableString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}