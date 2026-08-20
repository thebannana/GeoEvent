import '../../../core/utils/json_helpers.dart';
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

  bool get hasAccessToken => accessToken.trim().isNotEmpty;

  bool get hasRefreshToken => refreshToken.trim().isNotEmpty;

  bool get hasTokens => hasAccessToken && hasRefreshToken;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'] ?? json['User'];

    return AuthResponse(
      accessToken: (json['accessToken'] ?? json['AccessToken'] ?? '')
          .toString()
          .trim(),
      refreshToken: (json['refreshToken'] ?? json['RefreshToken'] ?? '')
          .toString()
          .trim(),
      expiresAt: JsonHelpers.parseDateTime(
        json['expiresAt'] ?? json['ExpiresAt'],
      ),
      user: _parseUser(rawUser),
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

  static AuthUser? _parseUser(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return AuthUser.fromJson(raw);
    }

    if (raw is Map) {
      return AuthUser.fromJson(
        Map<String, dynamic>.from(raw),
      );
    }

    return null;
  }
}