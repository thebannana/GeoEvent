class PublicProfileUser {
  final int userId;
  final String username;
  final String fullName;
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

  const PublicProfileUser({
    required this.userId,
    required this.username,
    required this.fullName,
    required this.imageUrl,
    required this.bio,
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
    final username = (json['username'] as String? ?? '').trim();
    final firstName = (json['firstName'] as String?)?.trim() ?? '';
    final lastName = (json['lastName'] as String?)?.trim() ?? '';
    final computed = '$firstName $lastName'.trim();

    bool readBool(dynamic value, {bool fallback = false}) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true' || normalized == '1') return true;
        if (normalized == 'false' || normalized == '0') return false;
      }
      return fallback;
    }

    return PublicProfileUser(
      userId: (json['userId'] as num).toInt(),
      username: username,
      fullName: computed.isEmpty ? username : computed,
      imageUrl: _normalizeNullable(json['imageUrl']),
      bio: _normalizeNullable(json['bio']),
      isVerified: readBool(json['isVerified']),
      eventsCount: (json['eventsCount'] as num?)?.toInt() ?? 0,
      followersCount: (json['followersCount'] as num?)?.toInt() ?? 0,
      followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      ratingsCount: (json['ratingsCount'] as num?)?.toInt() ?? 0,
      myRating: (json['myRating'] as num?)?.toInt(),
      myReviewComment: _normalizeNullable(json['myReviewComment']),
    );
  }

  static String? _normalizeNullable(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }
}