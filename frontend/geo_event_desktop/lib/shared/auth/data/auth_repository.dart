import '../models/auth_response.dart';
import '../models/auth_state.dart';
import '../models/login_request.dart';
import '../models/reset_password_request.dart';
import 'auth_api.dart';
import 'auth_local_storage.dart';

class AuthRepository {
  AuthRepository({
    required this.api,
    required this.localStorage,
  });

  final AuthApi api;
  final AuthLocalStorage localStorage;

  Future<AuthState> restoreSession() {
    return localStorage.readSession();
  }

  Future<AuthResponse> login(
    LoginRequest request, {
    required bool rememberMe,
  }) async {
    final response = await api.login(request);

    if (response.hasTokens) {
      if (rememberMe) {
        await localStorage.saveSession(
          response,
          rememberMe: true,
        );
      } else {
        await localStorage.clearSession();
      }
    }

    return response;
  }

  Future<void> forgotPassword(String email) {
    return api.forgotPassword(email);
  }

  Future<void> resetPassword(ResetPasswordRequest request) {
    return api.resetPassword(request);
  }

  Future<AuthResponse> refresh(String refreshToken) async {
    final response = await api.refresh(refreshToken);

    if (response.hasTokens && localStorage.shouldPersistSession) {
      await localStorage.saveSession(
        response,
        rememberMe: true,
      );
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