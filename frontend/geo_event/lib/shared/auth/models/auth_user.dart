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

  String get fullName => '$firstName $lastName'.trim();

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt'] ?? json['CreatedAt'];

    return AuthUser(
      userId: (json['userId'] ?? json['UserId'] ?? 0) as int,
      username: (json['username'] ?? json['Username'] ?? '').toString(),
      email: (json['email'] ?? json['Email'] ?? '').toString(),
      firstName: (json['firstName'] ?? json['FirstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? json['LastName'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? json['ImageUrl']) as String?,
      role: (json['role'] ?? json['Role'] ?? 'User').toString(),
      isVerified: (json['isVerified'] ?? json['IsVerified'] ?? false) as bool,
      createdAt: DateTime.parse(createdAtRaw.toString()),
      cityId: (json['cityId'] ?? json['CityId']) as int?,
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
      'createdAt': createdAt.toUtc().toIso8601String(),
      'cityId': cityId,
    };
  }
}