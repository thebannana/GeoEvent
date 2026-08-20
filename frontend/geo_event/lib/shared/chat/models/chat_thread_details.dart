import 'chat_event_info.dart';
import 'chat_participant.dart';
import 'chat_thread_type.dart';

class ChatThreadDetails {
  final int threadId;
  final ChatThreadType type;
  final String title;
  final String? imageUrl;
  final int? otherUserId;
  final String? otherUserDisplayName;
  final String? otherUserUsername;
  final String? otherUserAvatarUrl;
  final bool otherUserIsOnline;
  final DateTime? otherUserLastActiveAt;
  final ChatEventInfo? eventInfo;
  final List<ChatParticipant> participants;

  const ChatThreadDetails({
    required this.threadId,
    required this.type,
    required this.title,
    required this.imageUrl,
    required this.otherUserId,
    required this.otherUserDisplayName,
    required this.otherUserUsername,
    required this.otherUserAvatarUrl,
    required this.otherUserIsOnline,
    required this.otherUserLastActiveAt,
    required this.eventInfo,
    required this.participants,
  });

  factory ChatThreadDetails.fromJson(Map<String, dynamic> json) {
    final rawParticipants = json['participants'] as List<dynamic>? ?? const [];

    return ChatThreadDetails(
      threadId: (json['threadId'] as num?)?.toInt() ?? 0,
      type: ChatThreadTypeX.fromJson(json['type']?.toString()),
      title: json['title']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      otherUserId: (json['otherUserId'] as num?)?.toInt(),
      otherUserDisplayName: json['otherUserDisplayName']?.toString(),
      otherUserUsername: json['otherUserUsername']?.toString(),
      otherUserAvatarUrl: json['otherUserAvatarUrl']?.toString(),
      otherUserIsOnline: json['otherUserIsOnline'] as bool? ?? false,
      otherUserLastActiveAt: json['otherUserLastActiveAt'] != null
          ? DateTime.tryParse(json['otherUserLastActiveAt'].toString())?.toUtc()
          : null,
      eventInfo: json['eventInfo'] is Map
          ? ChatEventInfo.fromJson(
              Map<String, dynamic>.from(json['eventInfo'] as Map),
            )
          : null,
      participants: rawParticipants
          .whereType<Map>()
          .map((e) => ChatParticipant.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
    );
  }

  ChatThreadDetails copyWith({
    int? threadId,
    ChatThreadType? type,
    String? title,
    String? imageUrl,
    bool clearImageUrl = false,
    int? otherUserId,
    bool clearOtherUserId = false,
    String? otherUserDisplayName,
    bool clearOtherUserDisplayName = false,
    String? otherUserUsername,
    bool clearOtherUserUsername = false,
    String? otherUserAvatarUrl,
    bool clearOtherUserAvatarUrl = false,
    bool? otherUserIsOnline,
    DateTime? otherUserLastActiveAt,
    bool clearOtherUserLastActiveAt = false,
    ChatEventInfo? eventInfo,
    bool clearEventInfo = false,
    List<ChatParticipant>? participants,
  }) {
    return ChatThreadDetails(
      threadId: threadId ?? this.threadId,
      type: type ?? this.type,
      title: title ?? this.title,
      imageUrl: clearImageUrl ? null : imageUrl ?? this.imageUrl,
      otherUserId: clearOtherUserId ? null : otherUserId ?? this.otherUserId,
      otherUserDisplayName: clearOtherUserDisplayName
          ? null
          : otherUserDisplayName ?? this.otherUserDisplayName,
      otherUserUsername: clearOtherUserUsername
          ? null
          : otherUserUsername ?? this.otherUserUsername,
      otherUserAvatarUrl: clearOtherUserAvatarUrl
          ? null
          : otherUserAvatarUrl ?? this.otherUserAvatarUrl,
      otherUserIsOnline: otherUserIsOnline ?? this.otherUserIsOnline,
      otherUserLastActiveAt: clearOtherUserLastActiveAt
          ? null
          : otherUserLastActiveAt ?? this.otherUserLastActiveAt,
      eventInfo: clearEventInfo ? null : eventInfo ?? this.eventInfo,
      participants: participants ?? this.participants,
    );
  }
}