class ChatParticipant {
  final int userId;
  final String displayName;
  final String username;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime? lastActiveAt;
  final DateTime? joinedAt;

  const ChatParticipant({
    required this.userId,
    required this.displayName,
    required this.username,
    required this.avatarUrl,
    required this.isOnline,
    required this.lastActiveAt,
    required this.joinedAt,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      userId: (json['userId'] as num).toInt(),
      displayName: json['displayName'] as String? ?? '',
      username: json['username'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.tryParse(json['lastActiveAt'] as String)
          : null,
      joinedAt: json['joinedAt'] != null
          ? DateTime.tryParse(json['joinedAt'] as String)
          : null,
    );
  }
}