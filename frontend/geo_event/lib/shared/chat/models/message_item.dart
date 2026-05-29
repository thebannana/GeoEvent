class MessageItem {
  final int id;
  final int senderId;
  final int recipientId;
  final int? eventId;
  final String content;
  final bool isRead;
  final int likesCount;
  final DateTime sentAt;
  final DateTime? readAt;
  final DateTime? editedAt;
  final String senderDisplayName;
  final String? senderAvatarUrl;
  final String recipientDisplayName;
  final String? recipientAvatarUrl;

  const MessageItem({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.eventId,
    required this.content,
    required this.isRead,
    required this.likesCount,
    required this.sentAt,
    required this.readAt,
    required this.editedAt,
    required this.senderDisplayName,
    required this.senderAvatarUrl,
    required this.recipientDisplayName,
    required this.recipientAvatarUrl,
  });

  factory MessageItem.fromJson(Map<String, dynamic> json) {
    return MessageItem(
      id: json['id'] as int,
      senderId: json['senderId'] as int,
      recipientId: json['recipientId'] as int,
      eventId: json['eventId'] as int?,
      content: (json['content'] as String?) ?? '',
      isRead: (json['isRead'] as bool?) ?? false,
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      sentAt: DateTime.parse(json['sentAt'] as String),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt'] as String) : null,
      editedAt: json['editedAt'] != null ? DateTime.parse(json['editedAt'] as String) : null,
      senderDisplayName: (json['senderDisplayName'] as String?) ?? '',
      senderAvatarUrl: json['senderAvatarUrl'] as String?,
      recipientDisplayName: (json['recipientDisplayName'] as String?) ?? '',
      recipientAvatarUrl: json['recipientAvatarUrl'] as String?,
    );
  }

  MessageItem copyWith({
    int? id,
    int? senderId,
    int? recipientId,
    int? eventId,
    String? content,
    bool? isRead,
    int? likesCount,
    DateTime? sentAt,
    DateTime? readAt,
    DateTime? editedAt,
    String? senderDisplayName,
    String? senderAvatarUrl,
    String? recipientDisplayName,
    String? recipientAvatarUrl,
  }) {
    return MessageItem(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      eventId: eventId ?? this.eventId,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      likesCount: likesCount ?? this.likesCount,
      sentAt: sentAt ?? this.sentAt,
      readAt: readAt ?? this.readAt,
      editedAt: editedAt ?? this.editedAt,
      senderDisplayName: senderDisplayName ?? this.senderDisplayName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      recipientDisplayName: recipientDisplayName ?? this.recipientDisplayName,
      recipientAvatarUrl: recipientAvatarUrl ?? this.recipientAvatarUrl,
    );
  }
}