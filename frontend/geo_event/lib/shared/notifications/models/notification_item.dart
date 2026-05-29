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
      notificationId: json['notificationId'] as int,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      isRead: json['isRead'] as bool,
      userId: json['userId'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
    );
  }

  NotificationItem copyWith({bool? isRead, DateTime? readAt}) {
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