import '../models/auth_response.dart';
import '../models/auth_state.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
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

  Future<AuthResponse> login(LoginRequest request) async {
    final response = await api.login(request);
    await _persistIfAuthenticated(response);
    return response;
  }

  Future<AuthResponse> register(RegisterRequest request) async {
    final response = await api.register(request);
    await _persistIfAuthenticated(response);
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
    await _persistIfAuthenticated(response);
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

  Future<void> _persistIfAuthenticated(AuthResponse response) async {
    if (response.hasTokens) {
      await localStorage.saveSession(response);
    }
  }
}