class PublicUserProfileDto {
  final int userId;
  final String username;
  final String firstName;
  final String lastName;
  final String? imageUrl;
  final String? bio;
  final bool isVerified;
  final int eventsCount;
  final int followersCount;
  final int followingCount;
  final double averageRating;
  final int ratingsCount;
  final int? myRating;
  final String? myReviewComment;
  final DateTime createdAt;

  const PublicUserProfileDto({
    required this.userId,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.imageUrl,
    this.bio,
    required this.isVerified,
    this.eventsCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.averageRating = 0.0,
    this.ratingsCount = 0,
    this.myRating,
    this.myReviewComment,
    required this.createdAt,
  });

  String get fullName {
    final value = '$firstName $lastName'.trim();
    return value.isEmpty ? username : value;
  }

  factory PublicUserProfileDto.fromJson(Map<String, dynamic> json) {
    return PublicUserProfileDto(
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      username: (json['username'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      imageUrl: _normalizeNullableString(json['imageUrl']),
      bio: _normalizeNullableString(json['bio']),
      isVerified: json['isVerified'] == true,
      eventsCount: (json['eventsCount'] as num?)?.toInt() ?? 0,
      followersCount: (json['followersCount'] as num?)?.toInt() ?? 0,
      followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      ratingsCount: (json['ratingsCount'] as num?)?.toInt() ?? 0,
      myRating: (json['myRating'] as num?)?.toInt(),
      myReviewComment: _normalizeNullableString(json['myReviewComment']),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static String? _normalizeNullableString(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }
}