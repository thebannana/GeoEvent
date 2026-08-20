import '../../../core/utils/json_helpers.dart';
import 'chat_thread_type.dart';

class ConversationSummary {
  final int threadId;
  final ChatThreadType type;
  final String title;
  final String? imageUrl;
  final int? otherUserId;
  final String? otherUserDisplayName;
  final String? otherUserUsername;
  final int? eventId;
  final String lastMessageContent;
  final DateTime lastMessageSentAt;
  final int unreadCount;
  final bool isLastMessageFromMe;
  final bool isOnline;
  final DateTime? lastActiveAt;

  const ConversationSummary({
    required this.threadId,
    required this.type,
    required this.title,
    required this.imageUrl,
    required this.otherUserId,
    required this.otherUserDisplayName,
    required this.otherUserUsername,
    required this.eventId,
    required this.lastMessageContent,
    required this.lastMessageSentAt,
    required this.unreadCount,
    required this.isLastMessageFromMe,
    required this.isOnline,
    required this.lastActiveAt,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    String? nullableString(dynamic value) {
      final text = value?.toString().trim();

      if (text == null || text.isEmpty) {
        return null;
      }

      return text;
    }

    final displayName = nullableString(
      json['otherUserDisplayName'],
    );

    final username = nullableString(
      json['otherUserUsername'],
    );

    final title = nullableString(json['title']) ??
        displayName ??
        username ??
        '';

    return ConversationSummary(
      threadId: JsonHelpers.asInt(json['threadId']) ?? 0,
      type: ChatThreadTypeX.fromJson(
        json['threadType']?.toString() ??
            json['type']?.toString(),
      ),
      title: title,
      imageUrl: nullableString(
        json['imageUrl'] ??
            json['otherUserAvatarUrl'],
      ),
      otherUserId: JsonHelpers.asInt(json['otherUserId']),
      otherUserDisplayName: displayName,
      otherUserUsername: username,
      eventId: JsonHelpers.asInt(json['eventId']),
      lastMessageContent:
          json['lastMessageContent']?.toString() ?? '',
      lastMessageSentAt:
          JsonHelpers.parseDateTime(json['lastMessageSentAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      unreadCount:
          JsonHelpers.asInt(json['unreadCount']) ?? 0,
      isLastMessageFromMe:
          JsonHelpers.asBool(json['isLastMessageFromMe']),
      isOnline: JsonHelpers.asBool(
        json['isOnline'] ??
            json['otherUserIsOnline'],
      ),
      lastActiveAt: JsonHelpers.parseDateTime(
        json['lastActiveAt'] ??
            json['otherUserLastActiveAt'],
      ),
    );
  }

  ConversationSummary copyWith({
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
    int? eventId,
    bool clearEventId = false,
    String? lastMessageContent,
    DateTime? lastMessageSentAt,
    int? unreadCount,
    bool? isLastMessageFromMe,
    bool? isOnline,
    DateTime? lastActiveAt,
    bool clearLastActiveAt = false,
  }) {
    return ConversationSummary(
      threadId: threadId ?? this.threadId,
      type: type ?? this.type,
      title: title ?? this.title,
      imageUrl: clearImageUrl
          ? null
          : imageUrl ?? this.imageUrl,
      otherUserId: clearOtherUserId
          ? null
          : otherUserId ?? this.otherUserId,
      otherUserDisplayName: clearOtherUserDisplayName
          ? null
          : otherUserDisplayName ??
              this.otherUserDisplayName,
      otherUserUsername: clearOtherUserUsername
          ? null
          : otherUserUsername ??
              this.otherUserUsername,
      eventId: clearEventId
          ? null
          : eventId ?? this.eventId,
      lastMessageContent:
          lastMessageContent ?? this.lastMessageContent,
      lastMessageSentAt:
          lastMessageSentAt ?? this.lastMessageSentAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isLastMessageFromMe:
          isLastMessageFromMe ??
              this.isLastMessageFromMe,
      isOnline: isOnline ?? this.isOnline,
      lastActiveAt: clearLastActiveAt
          ? null
          : lastActiveAt ?? this.lastActiveAt,
    );
  }
}