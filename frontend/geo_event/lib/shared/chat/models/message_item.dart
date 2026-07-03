class MessageItem {
  final int id;
  final int threadId;
  final int senderId;
  final String content;
  final bool isRead;
  final int likesCount;
  final bool isLikedByMe;
  final DateTime sentAt;
  final DateTime? readAt;
  final DateTime? editedAt;
  final String? senderDisplayName;
  final String? senderAvatarUrl;
  final int? replyToMessageId;
  final String? replyPreview;
  final String? replySenderName;

  const MessageItem({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.content,
    required this.isRead,
    required this.likesCount,
    required this.isLikedByMe,
    required this.sentAt,
    required this.readAt,
    required this.editedAt,
    required this.senderDisplayName,
    required this.senderAvatarUrl,
    required this.replyToMessageId,
    required this.replyPreview,
    required this.replySenderName,
  });

  factory MessageItem.fromJson(Map<String, dynamic> json) {
    final replyTo = json['replyTo'];
    final replyMap = replyTo is Map ? Map<String, dynamic>.from(replyTo) : null;

    return MessageItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      threadId: (json['threadId'] as num?)?.toInt() ?? 0,
      senderId: (json['senderId'] as num?)?.toInt() ?? 0,
      content: json['content']?.toString() ?? '',
      isRead: json['isRead'] as bool? ?? false,
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      isLikedByMe: json['isLikedByMe'] as bool? ?? false,
      sentAt: DateTime.tryParse(json['sentAt']?.toString() ?? '')
              ?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'].toString())?.toLocal()
          : null,
      editedAt: json['editedAt'] != null
          ? DateTime.tryParse(json['editedAt'].toString())?.toLocal()
          : null,
      senderDisplayName: json['senderDisplayName']?.toString(),
      senderAvatarUrl: json['senderAvatarUrl']?.toString(),
      replyToMessageId: (json['replyToMessageId'] as num?)?.toInt() ??
          (replyMap?['messageId'] as num?)?.toInt() ??
          (replyMap?['id'] as num?)?.toInt(),
      replyPreview: json['replyPreview']?.toString() ??
          replyMap?['contentPreview']?.toString() ??
          replyMap?['content']?.toString(),
      replySenderName: json['replySenderName']?.toString() ??
          replyMap?['senderDisplayName']?.toString() ??
          replyMap?['senderName']?.toString(),
    );
  }

  MessageItem copyWith({
    int? id,
    int? threadId,
    int? senderId,
    String? content,
    bool? isRead,
    int? likesCount,
    bool? isLikedByMe,
    DateTime? sentAt,
    DateTime? readAt,
    bool clearReadAt = false,
    DateTime? editedAt,
    bool clearEditedAt = false,
    String? senderDisplayName,
    bool clearSenderDisplayName = false,
    String? senderAvatarUrl,
    bool clearSenderAvatarUrl = false,
    int? replyToMessageId,
    bool clearReplyToMessageId = false,
    String? replyPreview,
    bool clearReplyPreview = false,
    String? replySenderName,
    bool clearReplySenderName = false,
  }) {
    return MessageItem(
      id: id ?? this.id,
      threadId: threadId ?? this.threadId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      likesCount: likesCount ?? this.likesCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      sentAt: sentAt ?? this.sentAt,
      readAt: clearReadAt ? null : readAt ?? this.readAt,
      editedAt: clearEditedAt ? null : editedAt ?? this.editedAt,
      senderDisplayName: clearSenderDisplayName
          ? null
          : senderDisplayName ?? this.senderDisplayName,
      senderAvatarUrl: clearSenderAvatarUrl
          ? null
          : senderAvatarUrl ?? this.senderAvatarUrl,
      replyToMessageId: clearReplyToMessageId
          ? null
          : replyToMessageId ?? this.replyToMessageId,
      replyPreview:
          clearReplyPreview ? null : replyPreview ?? this.replyPreview,
      replySenderName: clearReplySenderName
          ? null
          : replySenderName ?? this.replySenderName,
    );
  }
}