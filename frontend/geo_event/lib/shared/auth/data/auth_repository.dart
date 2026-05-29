import '../models/auth_response.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import 'auth_api.dart';

class AuthRepository {
  final AuthApi api;

  AuthRepository(this.api);

  Future<AuthResponse> login(LoginRequest request) {
    return api.login(request);
  }

  Future<AuthResponse?> register(RegisterRequest request) {
    return api.register(request);
  }

  Future<void> forgotPassword(String email) {
    return api.forgotPassword(email);
  }

  Future<AuthResponse> refresh(String refreshToken) {
    return api.refresh(refreshToken);
  }

  Future<void> logout(String refreshToken) {
    return api.logout(refreshToken);
  }
}