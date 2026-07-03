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
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
      final parsed =
          DateTime.tryParse(value.toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return parsed.toLocal();
    }

    DateTime? parseNullableDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString())?.toLocal();
    }

    String? parseNullableString(dynamic value) {
      final text = value?.toString().trim();
      if (text == null || text.isEmpty) return null;
      return text;
    }

    final otherUserDisplayName = parseNullableString(
      json['otherUserDisplayName'],
    );
    final otherUserUsername = parseNullableString(
      json['otherUserUsername'],
    );

    final title = parseNullableString(json['title']) ??
        otherUserDisplayName ??
        otherUserUsername ??
        '';

    return ConversationSummary(
      threadId: (json['threadId'] as num?)?.toInt() ?? 0,
      type: ChatThreadTypeX.fromJson(
        json['threadType']?.toString() ?? json['type']?.toString(),
      ),
      title: title,
      imageUrl: parseNullableString(
        json['imageUrl'] ?? json['otherUserAvatarUrl'],
      ),
      otherUserId: (json['otherUserId'] as num?)?.toInt(),
      otherUserDisplayName: otherUserDisplayName,
      otherUserUsername: otherUserUsername,
      eventId: (json['eventId'] as num?)?.toInt(),
      lastMessageContent: json['lastMessageContent']?.toString() ?? '',
      lastMessageSentAt: parseDate(json['lastMessageSentAt']),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      isLastMessageFromMe: json['isLastMessageFromMe'] as bool? ?? false,
      isOnline:
          (json['isOnline'] ?? json['otherUserIsOnline']) as bool? ?? false,
      lastActiveAt: parseNullableDate(
        json['lastActiveAt'] ?? json['otherUserLastActiveAt'],
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
      imageUrl: clearImageUrl ? null : imageUrl ?? this.imageUrl,
      otherUserId: clearOtherUserId ? null : otherUserId ?? this.otherUserId,
      otherUserDisplayName: clearOtherUserDisplayName
          ? null
          : otherUserDisplayName ?? this.otherUserDisplayName,
      otherUserUsername: clearOtherUserUsername
          ? null
          : otherUserUsername ?? this.otherUserUsername,
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