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
  final DateTime createdAt;
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

  String get fullName => '$firstName $lastName'.trim();

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] as int,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      imageUrl: json['imageUrl'] as String?,
      role: json['role'] as String? ?? 'User',
      isVerified: json['isVerified'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      cityId: json['cityId'] as int?,
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
      cityId: json['cityId'] as int,
      cityName: json['cityName'] as String? ?? '',
      countryName: json['countryName'] as String?,
      divisionName: json['divisionName'] as String?,
    );
  }
}