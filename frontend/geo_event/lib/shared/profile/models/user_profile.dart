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
  final int? cityId;

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
    required this.cityId,
  });

  String get fullName {
    final full = '$firstName $lastName'.trim();
    return full.isEmpty ? username : full;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt']?.toString();

    return UserProfile(
      userId: (json['userId'] as num).toInt(),
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      role: (json['role'] ?? 'User').toString(),
      isVerified: json['isVerified'] as bool? ?? false,
      createdAt: createdAtRaw == null || createdAtRaw.isEmpty
          ? null
          : DateTime.tryParse(createdAtRaw),
      cityId: (json['cityId'] as num?)?.toInt(),
    );
  }
}

class CitySearchResult {
  final int cityId;
  final String cityName;
  final String? countryName;
  final String? divisionName;

  const CitySearchResult({
    required this.cityId,
    required this.cityName,
    required this.countryName,
    required this.divisionName,
  });

  String get displayLabel {
    final parts = [
      cityName,
      if ((divisionName ?? '').trim().isNotEmpty) divisionName,
      if ((countryName ?? '').trim().isNotEmpty) countryName,
    ];
    return parts.join(', ');
  }

  factory CitySearchResult.fromJson(Map<String, dynamic> json) {
    return CitySearchResult(
      cityId: (json['cityId'] as num).toInt(),
      cityName: (json['cityName'] ?? '').toString(),
      countryName: json['countryName']?.toString(),
      divisionName: json['divisionName']?.toString(),
    );
  }
}