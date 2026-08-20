import '../../../../core/utils/json_helpers.dart';

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

  /// Parsed from the API and retained as UTC.
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

    return value == null || value.isEmpty
        ? 'No phone number'
        : value;
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

    return date.toUtc().year.toString();
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: JsonHelpers.asInt(
            json['userId'] ?? json['UserId'],
          ) ??
          0,
      username: (json['username'] ?? json['Username'] ?? '')
          .toString()
          .trim(),
      email: (json['email'] ?? json['Email'] ?? '')
          .toString()
          .trim(),
      firstName: (json['firstName'] ?? json['FirstName'] ?? '')
          .toString()
          .trim(),
      lastName: (json['lastName'] ?? json['LastName'] ?? '')
          .toString()
          .trim(),
      phoneNumber: JsonHelpers.normalize(
        json['phoneNumber'] ?? json['PhoneNumber'],
      ),
      imageUrl: JsonHelpers.normalize(
        json['imageUrl'] ?? json['ImageUrl'],
      ),
      role: (json['role'] ?? json['Role'] ?? 'User')
          .toString()
          .trim(),
      isVerified: JsonHelpers.asBool(
        json['isVerified'] ?? json['IsVerified'],
      ),
      isBanned: JsonHelpers.asBool(
        json['isBanned'] ?? json['IsBanned'],
      ),
      createdAt: JsonHelpers.parseDateTime(
        json['createdAt'] ?? json['CreatedAt'],
      ),
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
      phoneNumber: clearPhoneNumber
          ? null
          : phoneNumber ?? this.phoneNumber,
      imageUrl: clearImageUrl
          ? null
          : imageUrl ?? this.imageUrl,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      isBanned: isBanned ?? this.isBanned,
      createdAt: createdAt ?? this.createdAt,
    );
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

  /// Parsed from the API and retained as UTC.
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

    return value == null || value.isEmpty
        ? 'No phone number'
        : value;
  }

  String get displayBio {
    final value = bio?.trim();

    return value == null || value.isEmpty
        ? 'No bio added.'
        : value;
  }

  bool get hasProfileImage {
    final value = imageUrl?.trim();
    return value != null && value.isNotEmpty;
  }

  factory AdminUserProfileDetails.fromJson(Map<String, dynamic> json) {
    return AdminUserProfileDetails(
      userId: JsonHelpers.asInt(
            json['userId'] ?? json['UserId'],
          ) ??
          0,
      username: (json['username'] ?? json['Username'] ?? '')
          .toString()
          .trim(),
      email: (json['email'] ?? json['Email'] ?? '')
          .toString()
          .trim(),
      firstName: (json['firstName'] ?? json['FirstName'] ?? '')
          .toString()
          .trim(),
      lastName: (json['lastName'] ?? json['LastName'] ?? '')
          .toString()
          .trim(),
      phoneNumber: JsonHelpers.normalize(
        json['phoneNumber'] ?? json['PhoneNumber'],
      ),
      imageUrl: JsonHelpers.normalize(
        json['imageUrl'] ?? json['ImageUrl'],
      ),
      bio: JsonHelpers.normalize(
        json['bio'] ?? json['Bio'],
      ),
      role: (json['role'] ?? json['Role'] ?? 'User')
          .toString()
          .trim(),
      isBanned: JsonHelpers.asBool(
        json['isBanned'] ?? json['IsBanned'],
      ),
      createdAt: JsonHelpers.parseDateTime(
        json['createdAt'] ?? json['CreatedAt'],
      ),
      eventsCount: JsonHelpers.asInt(
            json['eventsCount'] ?? json['EventsCount'],
          ) ??
          0,
      averageRating: JsonHelpers.asDouble(
        json['averageRating'] ?? json['AverageRating'],
      ),
      ratingsCount: JsonHelpers.asInt(
            json['ratingsCount'] ?? json['RatingsCount'],
          ) ??
          0,
    );
  }
}