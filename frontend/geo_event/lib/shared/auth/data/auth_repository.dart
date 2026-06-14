import '../models/auth_response.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import 'auth_api.dart';
import 'auth_local_storage.dart';

class AuthRepository {
  final AuthApi api;
  final AuthLocalStorage localStorage;

  AuthRepository({
    required this.api,
    required this.localStorage,
  });

  Future<AuthResponse> login(LoginRequest request) async {
    final response = await api.login(request);
    if (response.hasTokens) {
      await localStorage.saveSession(response);
    }
    return response;
  }

  Future<AuthResponse?> register(RegisterRequest request) async {
    final response = await api.register(request);
    if (response != null && response.hasTokens) {
      await localStorage.saveSession(response);
    }
    return response;
  }

  Future<void> forgotPassword(String email) {
    return api.forgotPassword(email);
  }

  Future<AuthResponse> refresh(String refreshToken) async {
    final response = await api.refresh(refreshToken);
    if (response.hasTokens) {
      await localStorage.saveSession(response);
    }
    return response;
  }

  Future<void> logout(String refreshToken) async {
    try {
      await api.logout(refreshToken);
    } finally {
      await localStorage.clearSession();
    }
  }

  Future<void> clearSession() {
    return localStorage.clearSession();
  }
}