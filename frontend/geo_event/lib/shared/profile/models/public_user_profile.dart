class PublicUserProfileDto {
  final int userId;
  final String username;
  final String firstName;
  final String lastName;
  final String? imageUrl;
  final bool isVerified;
  final int? cityId;
  final DateTime createdAt;

  const PublicUserProfileDto({
    required this.userId,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.imageUrl,
    required this.isVerified,
    required this.cityId,
    required this.createdAt,
  });

  String get fullName {
    final value = '$firstName $lastName'.trim();
    return value.isEmpty ? username : value;
  }

  factory PublicUserProfileDto.fromJson(Map<String, dynamic> json) {
    return PublicUserProfileDto(
      userId: (json['userId'] as num).toInt(),
      username: json['username']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      isVerified: json['isVerified'] == true,
      cityId: (json['cityId'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['createdAt'].toString()),
    );
  }
}