class Bookmark {
  final int bookmarkId;
  final String imageUrl;
  final DateTime savedAt;
  final String? memo;
  final int? eventId;

  const Bookmark({
    required this.bookmarkId,
    required this.imageUrl,
    required this.savedAt,
    this.memo,
    this.eventId,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
        bookmarkId: json['bookmarkId'] as int,
        imageUrl: json['imageUrl'] as String? ?? '',
        savedAt: DateTime.parse(json['savedAt'] as String),
        memo: json['memo'] as String?,
        eventId: json['eventId'] as int?,
      );
}