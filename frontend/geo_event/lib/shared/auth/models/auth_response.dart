import 'auth_user.dart';

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final DateTime? expiresAt;
  final AuthUser? user;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.user,
  });

  bool get hasTokens =>
      accessToken.isNotEmpty && refreshToken.isNotEmpty && user != null;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    final rawExpiresAt = json['expiresAt'];

    return AuthResponse(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      expiresAt: rawExpiresAt is String && rawExpiresAt.isNotEmpty
          ? DateTime.tryParse(rawExpiresAt)
          : null,
      user: rawUser is Map<String, dynamic>
          ? AuthUser.fromJson(rawUser)
          : rawUser is Map
              ? AuthUser.fromJson(Map<String, dynamic>.from(rawUser))
              : null,
    );
  }
}