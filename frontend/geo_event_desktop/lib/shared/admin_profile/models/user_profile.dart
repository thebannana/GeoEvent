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
  final bool isBanned;
  final DateTime? createdAt;

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
    required this.isBanned,
    required this.createdAt,
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
    final bannedRaw = json['isBanned'] ?? json['IsBanned'] ?? false;

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
      isBanned: _parseBool(bannedRaw),
      createdAt: _parseDateTime(createdAtRaw),
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
      'isBanned': isBanned,
      'createdAt': createdAt?.toUtc().toIso8601String(),
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
    bool? isBanned,
    DateTime? createdAt,
    bool clearPhoneNumber = false,
    bool clearImageUrl = false,
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
      isBanned: isBanned ?? this.isBanned,
      createdAt: createdAt ?? this.createdAt,
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

class AdminUserProfileDetails {
  final int userId;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? imageUrl;
  final String? bio;
  final String role;
  final bool isBanned;
  final DateTime? createdAt;
  final int eventsCount;
  final double averageRating;
  final int ratingsCount;

  const AdminUserProfileDetails({
    required this.userId,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.imageUrl,
    required this.bio,
    required this.role,
    required this.isBanned,
    required this.createdAt,
    required this.eventsCount,
    required this.averageRating,
    required this.ratingsCount,
  });

  String get fullName {
    final full = '$firstName $lastName'.trim();
    return full.isEmpty ? username : full;
  }

  String get displayUsername {
    final value = username.trim();
    if (value.isEmpty) return '@user';
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

  String get displayBio {
    final value = bio?.trim();
    return value == null || value.isEmpty ? 'No bio added.' : value;
  }

  bool get hasProfileImage {
    final value = imageUrl?.trim();
    return value != null && value.isNotEmpty;
  }

  factory AdminUserProfileDetails.fromJson(Map<String, dynamic> json) {
    final userIdRaw = json['userId'] ?? json['UserId'] ?? 0;
    final bannedRaw = json['isBanned'] ?? json['IsBanned'] ?? false;
    final createdAtRaw = json['createdAt'] ?? json['CreatedAt'];
    final eventsCountRaw = json['eventsCount'] ?? json['EventsCount'] ?? 0;
    final averageRatingRaw =
        json['averageRating'] ?? json['AverageRating'] ?? 0;
    final ratingsCountRaw = json['ratingsCount'] ?? json['RatingsCount'] ?? 0;

    return AdminUserProfileDetails(
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
      bio: _normalizeNullableString(
        json['bio'] ?? json['Bio'],
      ),
      role: (json['role'] ?? json['Role'] ?? 'User').toString().trim(),
      isBanned: _parseBool(bannedRaw),
      createdAt: _parseDateTime(createdAtRaw),
      eventsCount: (eventsCountRaw as num?)?.toInt() ?? 0,
      averageRating: (averageRatingRaw as num?)?.toDouble() ?? 0,
      ratingsCount: (ratingsCountRaw as num?)?.toInt() ?? 0,
    );
  }

  static String? _normalizeNullableString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    final text = value.toString().trim();
    if (text.isEmpty) return null;

    return DateTime.tryParse(text);
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    final normalized = value.toString().toLowerCase().trim();
    return normalized == 'true' || normalized == '1';
  }
}