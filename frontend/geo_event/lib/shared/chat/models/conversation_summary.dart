class ConversationSummary {
  final int otherUserId;
  final String lastMessageContent;
  final DateTime lastMessageSentAt;
  final int unreadCount;
  final bool isLastMessageFromMe;

  const ConversationSummary({
    required this.otherUserId,
    required this.lastMessageContent,
    required this.lastMessageSentAt,
    required this.unreadCount,
    required this.isLastMessageFromMe,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    return ConversationSummary(
      otherUserId: json['otherUserId'] as int? ?? 0,
      lastMessageContent: json['lastMessageContent'] as String? ?? '',
      lastMessageSentAt:
          DateTime.tryParse(json['lastMessageSentAt'] as String? ?? '') ??
              DateTime.now(),
      unreadCount: json['unreadCount'] as int? ?? 0,
      isLastMessageFromMe: json['isLastMessageFromMe'] as bool? ?? false,
    );
  }
}