class UserReview {
  final int ratingId;
  final int reviewerId;
  final String reviewerUsername;
  final String reviewerDisplayName;
  final String? reviewerImageUrl;
  final int ratedUserId;
  final int value;
  final String? comment;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserReview({
    required this.ratingId,
    required this.reviewerId,
    required this.reviewerUsername,
    required this.reviewerDisplayName,
    required this.reviewerImageUrl,
    required this.ratedUserId,
    required this.value,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserReview.fromJson(Map<String, dynamic> json) {
    return UserReview(
      ratingId: (json['ratingId'] as num).toInt(),
      reviewerId: (json['reviewerId'] as num).toInt(),
      reviewerUsername: json['reviewerUsername'] as String? ?? '',
      reviewerDisplayName: json['reviewerDisplayName'] as String? ?? '',
      reviewerImageUrl: json['reviewerImageUrl'] as String?,
      ratedUserId: (json['ratedUserId'] as num).toInt(),
      value: (json['value'] as num).toInt(),
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }
}