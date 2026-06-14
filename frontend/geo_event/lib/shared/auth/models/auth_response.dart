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
    final rawUser = json['user'] ?? json['User'];
    final rawExpiresAt = json['expiresAt'] ?? json['ExpiresAt'];

    return AuthResponse(
      accessToken:
          (json['accessToken'] ?? json['AccessToken'] ?? '').toString(),
      refreshToken:
          (json['refreshToken'] ?? json['RefreshToken'] ?? '').toString(),
      expiresAt: rawExpiresAt is String && rawExpiresAt.isNotEmpty
          ? DateTime.tryParse(rawExpiresAt)
          : rawExpiresAt is DateTime
              ? rawExpiresAt
              : null,
      user: rawUser is Map<String, dynamic>
          ? AuthUser.fromJson(rawUser)
          : rawUser is Map
              ? AuthUser.fromJson(Map<String, dynamic>.from(rawUser))
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt?.toUtc().toIso8601String(),
      'user': user?.toJson(),
    };
  }
}