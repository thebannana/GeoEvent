import 'chat_thread_type.dart';

class ConversationSummary {
  final int threadId;
  final ChatThreadType type;
  final String title;
  final String? imageUrl;
  final int? otherUserId;
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
    required this.eventId,
    required this.lastMessageContent,
    required this.lastMessageSentAt,
    required this.unreadCount,
    required this.isLastMessageFromMe,
    required this.isOnline,
    required this.lastActiveAt,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    return ConversationSummary(
      threadId: (json['threadId'] as num).toInt(),
      type: ChatThreadTypeX.fromJson(json['type'] as String?),
      title: json['title'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      otherUserId: (json['otherUserId'] as num?)?.toInt(),
      eventId: (json['eventId'] as num?)?.toInt(),
      lastMessageContent: json['lastMessageContent'] as String? ?? '',
      lastMessageSentAt: DateTime.tryParse(
            json['lastMessageSentAt'] as String? ?? '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      isLastMessageFromMe: json['isLastMessageFromMe'] as bool? ?? false,
      isOnline: json['isOnline'] as bool? ?? false,
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.tryParse(json['lastActiveAt'] as String)
          : null,
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
      imageUrl: clearImageUrl ? null : imageUrl ?? this.imageUrl,
      otherUserId: clearOtherUserId ? null : otherUserId ?? this.otherUserId,
      eventId: clearEventId ? null : eventId ?? this.eventId,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageSentAt: lastMessageSentAt ?? this.lastMessageSentAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isLastMessageFromMe: isLastMessageFromMe ?? this.isLastMessageFromMe,
      isOnline: isOnline ?? this.isOnline,
      lastActiveAt:
          clearLastActiveAt ? null : lastActiveAt ?? this.lastActiveAt,
    );
  }
}