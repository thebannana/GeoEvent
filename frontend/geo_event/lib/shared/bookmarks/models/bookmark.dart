class Bookmark {
  final int bookmarkId;
  final String imageUrl;
  final DateTime savedAt;
  final String? memo;
  final int? eventId;
  final int? userId;

  const Bookmark({
    required this.bookmarkId,
    required this.imageUrl,
    required this.savedAt,
    this.memo,
    this.eventId,
    this.userId,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      bookmarkId: (json['bookmarkId'] as num).toInt(),
      imageUrl: json['imageUrl'] as String? ?? '',
      savedAt: DateTime.parse(json['savedAt'] as String),
      memo: json['memo'] as String?,
      eventId: (json['eventId'] as num?)?.toInt(),
      userId: (json['userId'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookmarkId': bookmarkId,
      'imageUrl': imageUrl,
      'savedAt': savedAt.toIso8601String(),
      'memo': memo,
      'eventId': eventId,
      'userId': userId,
    };
  }

  Bookmark copyWith({
    int? bookmarkId,
    String? imageUrl,
    DateTime? savedAt,
    String? memo,
    bool clearMemo = false,
    int? eventId,
    int? userId,
  }) {
    return Bookmark(
      bookmarkId: bookmarkId ?? this.bookmarkId,
      imageUrl: imageUrl ?? this.imageUrl,
      savedAt: savedAt ?? this.savedAt,
      memo: clearMemo ? null : (memo ?? this.memo),
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
    );
  }
}