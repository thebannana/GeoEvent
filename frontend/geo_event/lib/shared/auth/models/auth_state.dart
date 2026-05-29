import 'auth_user.dart';

class AuthState {
  final String? accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final AuthUser? user;
  final bool isLoading;

  const AuthState({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.user,
    required this.isLoading,
  });

  const AuthState.initial()
      : accessToken = null,
        refreshToken = null,
        expiresAt = null,
        user = null,
        isLoading = false;

  bool get isAuthenticated =>
      accessToken != null &&
      accessToken!.isNotEmpty &&
      refreshToken != null &&
      refreshToken!.isNotEmpty &&
      user != null;

  AuthState copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    AuthUser? user,
    bool? isLoading,
    bool clearTokens = false,
  }) {
    if (clearTokens) {
      return const AuthState.initial();
    }

    return AuthState(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}