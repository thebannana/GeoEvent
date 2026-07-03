import 'auth_response.dart';
import 'auth_user.dart';

class AuthState {
  final String? accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final AuthUser? user;
  final bool isLoading;
  final bool isInitialized;

  const AuthState({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.user,
    required this.isLoading,
    required this.isInitialized,
  });

  const AuthState.initial()
      : accessToken = null,
        refreshToken = null,
        expiresAt = null,
        user = null,
        isLoading = false,
        isInitialized = false;

  const AuthState.unauthenticated({
    required this.isInitialized,
  })  : accessToken = null,
        refreshToken = null,
        expiresAt = null,
        user = null,
        isLoading = false;

  factory AuthState.authenticated(AuthResponse response) {
    return AuthState(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
      expiresAt: response.expiresAt,
      user: response.user,
      isLoading: false,
      isInitialized: true,
    );
  }

  bool get hasAccessToken =>
      accessToken != null && accessToken!.trim().isNotEmpty;

  bool get hasRefreshToken =>
      refreshToken != null && refreshToken!.trim().isNotEmpty;

  bool get isAuthenticated =>
      hasAccessToken && hasRefreshToken && user != null;

  AuthState copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    AuthUser? user,
    bool? isLoading,
    bool? isInitialized,
    bool clearSession = false,
  }) {
    if (clearSession) {
      return const AuthState.unauthenticated(isInitialized: true);
    }

    return AuthState(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}