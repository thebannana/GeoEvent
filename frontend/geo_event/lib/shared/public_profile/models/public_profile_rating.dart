class PublicProfileRating {
  final int userId;
  final double averageRating;
  final int ratingsCount;
  final int? myRating;

  const PublicProfileRating({
    required this.userId,
    required this.averageRating,
    required this.ratingsCount,
    required this.myRating,
  });

  factory PublicProfileRating.fromJson(Map<String, dynamic> json) {
    return PublicProfileRating(
      userId: (json['userId'] as num).toInt(),
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      ratingsCount: (json['ratingsCount'] as num?)?.toInt() ?? 0,
      myRating: (json['myRating'] as num?)?.toInt(),
    );
  }
}