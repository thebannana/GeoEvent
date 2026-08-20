class LikedEvent {
  final int eventId;
  final String title;
  final String? imageUrl;
  final DateTime likedAt;
  final bool isLiked;

  const LikedEvent({
    required this.eventId,
    required this.title,
    required this.imageUrl,
    required this.likedAt,
    required this.isLiked,
  });

  factory LikedEvent.fromJson(Map<String, dynamic> json) {
    final parsedLikedAt = DateTime.tryParse(json['likedAt']?.toString() ?? '');

    return LikedEvent(
      eventId: (json['eventId'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString().trim().isNotEmpty == true
          ? json['title'].toString().trim()
          : 'Liked event',
      imageUrl: json['imageUrl']?.toString(),
      likedAt: parsedLikedAt ?? DateTime.now().toUtc(),
      isLiked: json['isLiked'] == true,
    );
  }
}