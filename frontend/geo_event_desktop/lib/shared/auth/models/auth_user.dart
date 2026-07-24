import '../../../core/constants/app_roles.dart';

class AuthUser {
  final int userId;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? imageUrl;
  final String role;
  final bool isVerified;
  final DateTime? createdAt;

  const AuthUser({
    required this.userId,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.imageUrl,
    required this.role,
    required this.isVerified,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt'] ?? json['CreatedAt'];
    final userIdRaw = json['userId'] ?? json['UserId'] ?? 0;
    final verifiedRaw = json['isVerified'] ?? json['IsVerified'] ?? false;

    return AuthUser(
      userId: (userIdRaw as num?)?.toInt() ?? 0,
      username: (json['username'] ?? json['Username'] ?? '').toString().trim(),
      email: (json['email'] ?? json['Email'] ?? '').toString().trim(),
      firstName: (json['firstName'] ?? json['FirstName'] ?? '').toString().trim(),
      lastName: (json['lastName'] ?? json['LastName'] ?? '').toString().trim(),
      imageUrl: _normalizeNullableString(json['imageUrl'] ?? json['ImageUrl']),
      role: (json['role'] ?? json['Role'] ?? AppRoles.user).toString().trim(),
      isVerified: verifiedRaw is bool
          ? verifiedRaw
          : verifiedRaw.toString().toLowerCase() == 'true',
      createdAt: createdAtRaw == null
          ? null
          : DateTime.tryParse(createdAtRaw.toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'imageUrl': imageUrl,
      'role': role,
      'isVerified': isVerified,
      'createdAt': createdAt?.toUtc().toIso8601String(),
    };
  }

  static String? _normalizeNullableString(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }
}