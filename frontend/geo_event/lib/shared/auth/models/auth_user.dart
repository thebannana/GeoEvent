class AuthUser {
  final int userId;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? imageUrl;
  final String role;
  final bool isVerified;
  final DateTime createdAt;
  final int? cityId;

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
    required this.cityId,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      userId: json['userId'] as int,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      role: json['role'] as String? ?? 'User',
      isVerified: json['isVerified'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      cityId: json['cityId'] as int?,
    );
  }
}