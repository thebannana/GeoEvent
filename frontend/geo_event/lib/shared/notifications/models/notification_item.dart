class NotificationItem {
  final int notificationId;
  final String type;
  final String title;
  final String description;
  final String? imageUrl;
  final bool isRead;
  final int? userId;
  final DateTime createdAt;
  final DateTime? readAt;

  const NotificationItem({
    required this.notificationId,
    required this.type,
    required this.title,
    required this.description,
    this.imageUrl,
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
      imageUrl: (json['imageUrl'] as String?)?.trim().isEmpty == true
          ? null
          : (json['imageUrl'] as String?)?.trim(),
      isRead: json['isRead'] as bool? ?? false,
      userId: (json['userId'] as num?)?.toInt(),
      createdAt: DateTime.parse((json['createdAt'] ?? '').toString()).toLocal(),
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'].toString()).toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'type': type,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'isRead': isRead,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }

  NotificationItem copyWith({
    bool? isRead,
    DateTime? readAt,
    String? imageUrl,
  }) {
    return NotificationItem(
      notificationId: notificationId,
      type: type,
      title: title,
      description: description,
      imageUrl: imageUrl ?? this.imageUrl,
      isRead: isRead ?? this.isRead,
      userId: userId,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}