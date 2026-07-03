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
      reviewerUsername: (json['reviewerUsername'] as String? ?? '').trim(),
      reviewerDisplayName:
          (json['reviewerDisplayName'] as String? ?? '').trim(),
      reviewerImageUrl: _normalizeNullable(json['reviewerImageUrl']),
      ratedUserId: (json['ratedUserId'] as num).toInt(),
      value: (json['value'] as num).toInt(),
      comment: _normalizeNullable(json['comment']),
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String).toLocal()
          : null,
    );
  }

  static String? _normalizeNullable(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }
}