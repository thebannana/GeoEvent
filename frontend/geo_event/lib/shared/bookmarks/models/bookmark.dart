class Bookmark {
  final int bookmarkId;
  final String title;
  final String imageUrl;
  final DateTime savedAt;
  final String? memo;
  final int? eventId;
  final int? userId;

  const Bookmark({
    required this.bookmarkId,
    required this.title,
    required this.imageUrl,
    required this.savedAt,
    this.memo,
    this.eventId,
    this.userId,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    final savedAtRaw = json['savedAt'];

    return Bookmark(
      bookmarkId: (json['bookmarkId'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString().trim().isNotEmpty == true
          ? json['title'].toString().trim()
          : 'Saved event',
      imageUrl: json['imageUrl']?.toString() ?? '',
      savedAt: DateTime.tryParse(savedAtRaw?.toString() ?? '') ?? DateTime.now(),
      memo: _normalizeNullableString(json['memo']),
      eventId: (json['eventId'] as num?)?.toInt(),
      userId: (json['userId'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookmarkId': bookmarkId,
      'title': title,
      'imageUrl': imageUrl,
      'savedAt': savedAt.toUtc().toIso8601String(),
      'memo': memo,
      'eventId': eventId,
      'userId': userId,
    };
  }

  Bookmark copyWith({
    int? bookmarkId,
    String? title,
    String? imageUrl,
    DateTime? savedAt,
    String? memo,
    bool clearMemo = false,
    int? eventId,
    int? userId,
  }) {
    return Bookmark(
      bookmarkId: bookmarkId ?? this.bookmarkId,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      savedAt: savedAt ?? this.savedAt,
      memo: clearMemo ? null : (memo ?? this.memo),
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
    );
  }

  static String? _normalizeNullableString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}