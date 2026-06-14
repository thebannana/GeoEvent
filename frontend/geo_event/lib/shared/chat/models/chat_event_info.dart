class ChatEventInfo {
  final int eventId;
  final String title;
  final String? imageUrl;
  final String? venueName;
  final String? cityName;
  final DateTime? startsAt;
  final DateTime? endsAt;

  const ChatEventInfo({
    required this.eventId,
    required this.title,
    required this.imageUrl,
    required this.venueName,
    required this.cityName,
    required this.startsAt,
    required this.endsAt,
  });

  factory ChatEventInfo.fromJson(Map<String, dynamic> json) {
    final rawEventId = json['eventId'] ?? json['id'] ?? 0;

    int parseInt(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

DateTime? parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString())?.toLocal();
}

    return ChatEventInfo(
      eventId: parseInt(rawEventId),
      title: (json['eventTitle'] ??
              json['title'] ??
              json['name'] ??
              '') as String,
      imageUrl: (json['coverImageUrl'] ??
              json['imageUrl'] ??
              json['photoUrl']) as String?,
      venueName: json['venueName'] as String?,
      cityName: json['cityName'] as String?,
      startsAt: parseDate(json['startDateTime'] ?? json['startsAt']),
      endsAt: parseDate(json['endDateTime'] ?? json['endsAt']),
    );
  }
}