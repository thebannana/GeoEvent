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
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      displayName: json['displayName']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
      isOnline: json['isOnline'] as bool? ?? false,
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.tryParse(json['lastActiveAt'].toString())?.toUtc()
          : null,
      joinedAt: json['joinedAt'] != null
          ? DateTime.tryParse(json['joinedAt'].toString())?.toUtc()
          : null,
    );
  }
}