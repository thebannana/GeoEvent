import '../../../core/utils/json_helpers.dart';

class ChatEventInfo {
  final int eventId;
  final String title;
  final String? imageUrl;
  final DateTime? startsAt;
  final DateTime? endsAt;

  const ChatEventInfo({
    required this.eventId,
    required this.title,
    required this.imageUrl,
    required this.startsAt,
    required this.endsAt,
  });

  factory ChatEventInfo.fromJson(Map<String, dynamic> json) {
    return ChatEventInfo(
      eventId: JsonHelpers.asInt(json['eventId'] ?? json['id']) ?? 0,
      title: (json['eventTitle'] ?? json['title'] ?? json['name'] ?? '').toString(),
      imageUrl: (json['coverImageUrl'] ?? json['imageUrl'] ?? json['photoUrl'])
          ?.toString(),
      startsAt: JsonHelpers.parseDateTime(json['startDateTime'] ?? json['startsAt']),
      endsAt: JsonHelpers.parseDateTime(json['endDateTime'] ?? json['endsAt']),
    );
  }
}