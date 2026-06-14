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
  DateTime parseDate(dynamic value) {
    if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
    final parsed = DateTime.tryParse(value.toString()) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return parsed.toLocal();
  }

  DateTime? parseNullableDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  final resolvedTitle =
      (json['title'] ??
              json['otherUserDisplayName'] ??
              json['otherUserUsername'] ??
              '') as String;

  final resolvedImageUrl =
      (json['imageUrl'] ?? json['otherUserAvatarUrl']) as String?;

  final resolvedIsOnline =
      (json['isOnline'] ?? json['otherUserIsOnline']) as bool? ?? false;

  final resolvedLastActiveAt = parseNullableDate(
    json['lastActiveAt'] ?? json['otherUserLastActiveAt'],
  );

  return ConversationSummary(
    threadId: (json['threadId'] as num).toInt(),
    type: ChatThreadTypeX.fromJson(json['type'] as String?),
    title: resolvedTitle,
    imageUrl: resolvedImageUrl,
    otherUserId: (json['otherUserId'] as num?)?.toInt(),
    eventId: (json['eventId'] as num?)?.toInt(),
    lastMessageContent: json['lastMessageContent'] as String? ?? '',
    lastMessageSentAt: parseDate(json['lastMessageSentAt']),
    unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    isLastMessageFromMe: json['isLastMessageFromMe'] as bool? ?? false,
    isOnline: resolvedIsOnline,
    lastActiveAt: resolvedLastActiveAt,
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