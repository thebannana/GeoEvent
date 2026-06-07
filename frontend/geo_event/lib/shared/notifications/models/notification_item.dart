class NotificationItem {
  final int notificationId;
  final String type;
  final String title;
  final String description;
  final bool isRead;
  final int? userId;
  final DateTime createdAt;
  final DateTime? readAt;

  const NotificationItem({
    required this.notificationId,
    required this.type,
    required this.title,
    required this.description,
    required this.isRead,
    this.userId,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      notificationId: (json['notificationId'] as num).toInt(),
      type: (json['type'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      isRead: json['isRead'] as bool? ?? false,
      userId: (json['userId'] as num?)?.toInt(),
      createdAt: DateTime.parse((json['createdAt'] ?? '').toString()),
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'type': type,
      'title': title,
      'description': description,
      'isRead': isRead,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }

  NotificationItem copyWith({
    bool? isRead,
    DateTime? readAt,
  }) {
    return NotificationItem(
      notificationId: notificationId,
      type: type,
      title: title,
      description: description,
      isRead: isRead ?? this.isRead,
      userId: userId,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}