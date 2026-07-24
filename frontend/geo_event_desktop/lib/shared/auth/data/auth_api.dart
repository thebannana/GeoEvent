import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/auth_interceptor.dart';
import '../models/auth_response.dart';
import '../models/login_request.dart';
import '../models/reset_password_request.dart';

class AuthApi {
  const AuthApi({
    required this.publicDio,
    required this.authenticatedDio,
  });

  final Dio publicDio;
  final Dio authenticatedDio;

  Future<AuthResponse> login(LoginRequest request) async {
    final response = await publicDio.post(
      ApiEndpoints.adminLogin,
      data: request.toJson(),
      options: Options(
        extra: const {
          AuthInterceptor.requiresAuthKey: false,
        },
      ),
    );

    return _parseAuthResponse(
      response.data,
      fallbackMessage: 'Invalid login response format.',
    );
  }

  Future<void> forgotPassword(String email) async {
    await publicDio.post(
      ApiEndpoints.forgotPassword,
      data: {'email': email.trim()},
      options: Options(
        extra: const {
          AuthInterceptor.requiresAuthKey: false,
        },
      ),
    );
  }

  Future<void> resetPassword(ResetPasswordRequest request) async {
    await publicDio.post(
      ApiEndpoints.resetPassword,
      data: request.toJson(),
      options: Options(
        extra: const {
          AuthInterceptor.requiresAuthKey: false,
        },
      ),
    );
  }

  Future<AuthResponse> refresh(String refreshToken) async {
    final response = await publicDio.post(
      ApiEndpoints.refresh,
      data: {'refreshToken': refreshToken},
      options: Options(
        contentType: Headers.jsonContentType,
        extra: const {
          AuthInterceptor.requiresAuthKey: false,
        },
      ),
    );

    return _parseAuthResponse(
      response.data,
      fallbackMessage: 'Invalid refresh response format.',
    );
  }

  Future<void> logout(String refreshToken) async {
    await authenticatedDio.post(
      ApiEndpoints.logout,
      data: {'refreshToken': refreshToken},
      options: Options(
        contentType: Headers.jsonContentType,
      ),
    );
  }

  AuthResponse _parseAuthResponse(
    dynamic raw, {
    required String fallbackMessage,
  }) {
    final map = _asMap(raw);
    if (map == null) {
      throw FormatException(fallbackMessage);
    }

    return AuthResponse.fromJson(map);
  }

  Map<String, dynamic>? _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }

    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }

    return null;
  }
}