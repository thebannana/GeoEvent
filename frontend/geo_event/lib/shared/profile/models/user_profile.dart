class UserProfile {
  final int userId;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? imageUrl;
  final String role;
  final bool isVerified;
  final DateTime? createdAt;
  final double averageRating;
  final int ratingsCount;
  final int? myRating;

  const UserProfile({
    required this.userId,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.imageUrl,
    required this.role,
    required this.isVerified,
    required this.createdAt,
    this.averageRating = 0.0,
    this.ratingsCount = 0,
    this.myRating,
  });

  String get fullName {
    final full = '$firstName $lastName'.trim();
    return full.isEmpty ? username : full;
  }

  String get displayFullName => fullName;

  String get displayHeaderName => fullName;

  String get displayUsername {
    final value = username.trim();
    if (value.isEmpty) {
      return '@user';
    }

    return value.startsWith('@') ? value : '@$value';
  }

  String get displayEmail {
    final value = email.trim();
    return value.isEmpty ? 'No email' : value;
  }

  String get displayPhoneNumber {
    final value = phoneNumber?.trim();
    return value == null || value.isEmpty ? 'No phone number' : value;
  }

  bool get hasProfileImage {
    final value = imageUrl?.trim();
    return value != null && value.isNotEmpty;
  }

  String get displayJoinedYear {
    final date = createdAt;
    if (date == null) {
      return 'recently';
    }

    return date.year.toString();
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt'] ?? json['CreatedAt'];
    final userIdRaw = json['userId'] ?? json['UserId'] ?? 0;
    final verifiedRaw = json['isVerified'] ?? json['IsVerified'] ?? false;

    return UserProfile(
      userId: (userIdRaw as num?)?.toInt() ?? 0,
      username: (json['username'] ?? json['Username'] ?? '').toString().trim(),
      email: (json['email'] ?? json['Email'] ?? '').toString().trim(),
      firstName:
          (json['firstName'] ?? json['FirstName'] ?? '').toString().trim(),
      lastName: (json['lastName'] ?? json['LastName'] ?? '').toString().trim(),
      phoneNumber: _normalizeNullableString(
        json['phoneNumber'] ?? json['PhoneNumber'],
      ),
      imageUrl: _normalizeNullableString(
        json['imageUrl'] ?? json['ImageUrl'],
      ),
      role: (json['role'] ?? json['Role'] ?? 'User').toString().trim(),
      isVerified: _parseBool(verifiedRaw),
      createdAt: _parseDateTime(createdAtRaw),
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      ratingsCount: (json['ratingsCount'] as num?)?.toInt() ?? 0,
      myRating: (json['myRating'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'imageUrl': imageUrl,
      'role': role,
      'isVerified': isVerified,
      'createdAt': createdAt?.toUtc().toIso8601String(),
      'averageRating': averageRating,
      'ratingsCount': ratingsCount,
      'myRating': myRating,
    };
  }

  UserProfile copyWith({
    int? userId,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? imageUrl,
    String? role,
    bool? isVerified,
    DateTime? createdAt,
    double? averageRating,
    int? ratingsCount,
    int? myRating,
    bool clearPhoneNumber = false,
    bool clearImageUrl = false,
    bool clearMyRating = false,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: clearPhoneNumber ? null : phoneNumber ?? this.phoneNumber,
      imageUrl: clearImageUrl ? null : imageUrl ?? this.imageUrl,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      averageRating: averageRating ?? this.averageRating,
      ratingsCount: ratingsCount ?? this.ratingsCount,
      myRating: clearMyRating ? null : myRating ?? this.myRating,
    );
  }

  static String? _normalizeNullableString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    final text = value.toString().trim();
    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final normalized = value.toString().toLowerCase().trim();
    return normalized == 'true' || normalized == '1';
  }
}