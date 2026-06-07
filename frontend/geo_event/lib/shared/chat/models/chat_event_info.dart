class ChatEventInfo {
  final int eventId;
  final String title;
  final String? imageUrl;
  final String? venueName;
  final String? cityName;
  final DateTime? startsAt;

  const ChatEventInfo({
    required this.eventId,
    required this.title,
    required this.imageUrl,
    required this.venueName,
    required this.cityName,
    required this.startsAt,
  });

  factory ChatEventInfo.fromJson(Map<String, dynamic> json) {
    final rawEventId = json['eventId'];
    final eventId = rawEventId is num
        ? rawEventId.toInt()
        : int.parse(rawEventId.toString());

    return ChatEventInfo(
      eventId: eventId,
      title: json['title'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      venueName: json['venueName'] as String?,
      cityName: json['cityName'] as String?,
      startsAt: json['startsAt'] != null
          ? DateTime.tryParse(json['startsAt'].toString())
          : null,
    );
  }
}