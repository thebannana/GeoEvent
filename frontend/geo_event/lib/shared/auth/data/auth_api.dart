import 'package:dio/dio.dart';

import '../models/auth_response.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';

class AuthApi {
  final Dio dio;

  AuthApi(this.dio);

  Future<AuthResponse> login(LoginRequest request) async {
    final response = await dio.post(
      '/api/auth/login',
      data: request.toJson(),
    );

    return AuthResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<AuthResponse?> register(RegisterRequest request) async {
    final response = await dio.post(
      '/api/auth/register',
      data: request.toJson(),
    );

    final raw = response.data;
    if (raw is! Map) {
      return null;
    }

    final map = Map<String, dynamic>.from(raw);
    final parsed = AuthResponse.fromJson(map);

    if (!parsed.hasTokens) {
      return null;
    }

    return parsed;
  }

  Future<void> forgotPassword(String email) async {
    await dio.post(
      '/api/auth/forgot-password',
      data: {
        'email': email,
      },
    );
  }

  Future<AuthResponse> refresh(String refreshToken) async {
    final response = await dio.post(
      '/api/auth/refresh',
      data: refreshToken,
      options: Options(
        contentType: Headers.jsonContentType,
      ),
    );

    return AuthResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> logout(String refreshToken) async {
    await dio.post(
      '/api/auth/logout',
      data: refreshToken,
      options: Options(
        contentType: Headers.jsonContentType,
      ),
    );
  }
}