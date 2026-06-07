class PublicProfileUser {
  final int userId;
  final String username;
  final String fullName;
  final String? imageUrl;
  final String? bio;
  final String? cityName;
  final bool isVerified;
  final int eventsCount;
  final int followersCount;
  final int followingCount;
  final double averageRating;
  final int ratingsCount;
  final int? myRating;
  final String? myReviewComment;

  const PublicProfileUser({
    required this.userId,
    required this.username,
    required this.fullName,
    required this.imageUrl,
    required this.bio,
    required this.cityName,
    required this.isVerified,
    required this.eventsCount,
    required this.followersCount,
    required this.followingCount,
    required this.averageRating,
    required this.ratingsCount,
    required this.myRating,
    required this.myReviewComment,
  });

  factory PublicProfileUser.fromJson(Map<String, dynamic> json) {
    final firstName = (json['firstName'] as String?)?.trim() ?? '';
    final lastName = (json['lastName'] as String?)?.trim() ?? '';

    return PublicProfileUser(
      userId: (json['userId'] as num).toInt(),
      username: json['username'] as String? ?? '',
      fullName: '$firstName $lastName'.trim().isEmpty
          ? (json['username'] as String? ?? '')
          : '$firstName $lastName'.trim(),
      imageUrl: json['imageUrl'] as String?,
      bio: json['bio'] as String?,
      cityName: json['cityName'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      eventsCount: (json['eventsCount'] as num?)?.toInt() ?? 0,
      followersCount: (json['followersCount'] as num?)?.toInt() ?? 0,
      followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      ratingsCount: (json['ratingsCount'] as num?)?.toInt() ?? 0,
      myRating: (json['myRating'] as num?)?.toInt(),
      myReviewComment: json['myReviewComment'] as String?,
    );
  }
}