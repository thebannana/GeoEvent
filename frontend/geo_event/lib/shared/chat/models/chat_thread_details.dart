import 'chat_event_info.dart';
import 'chat_participant.dart';
import 'chat_thread_type.dart';

class ChatThreadDetails {
  final int threadId;
  final ChatThreadType type;
  final String title;
  final String? imageUrl;
  final int? otherUserId;
  final ChatEventInfo? eventInfo;
  final List<ChatParticipant> participants;

  const ChatThreadDetails({
    required this.threadId,
    required this.type,
    required this.title,
    required this.imageUrl,
    required this.otherUserId,
    required this.eventInfo,
    required this.participants,
  });

  factory ChatThreadDetails.fromJson(Map<String, dynamic> json) {
    final rawParticipants = json['participants'] as List<dynamic>? ?? const [];

    return ChatThreadDetails(
      threadId: (json['threadId'] as num).toInt(),
      type: ChatThreadTypeX.fromJson(json['type'] as String?),
      title: json['title'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      otherUserId: (json['otherUserId'] as num?)?.toInt(),
      eventInfo: json['eventInfo'] != null
          ? ChatEventInfo.fromJson(
              Map<String, dynamic>.from(json['eventInfo'] as Map),
            )
          : null,
      participants: rawParticipants
          .map((e) => ChatParticipant.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false),
    );
  }
}