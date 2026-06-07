class LikedEventDto {
  final int eventId;
  final String title;
  final String? imageUrl;
  final DateTime likedAt;
  final bool isLiked;

  const LikedEventDto({
    required this.eventId,
    required this.title,
    required this.imageUrl,
    required this.likedAt,
    required this.isLiked,
  });

  factory LikedEventDto.fromJson(Map<String, dynamic> json) {
    return LikedEventDto(
      eventId: (json['eventId'] as num).toInt(),
      title: json['title']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      likedAt: DateTime.parse(json['likedAt'].toString()),
      isLiked: json['isLiked'] == true,
    );
  }
}