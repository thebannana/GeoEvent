import '../../../core/utils/json_helpers.dart';

enum NotificationType {
  eventInvite,
  eventUpdate,
  eventCancelled,
  newFollower,
  ticketConfirmed,
  ticketCancelled,
  message,
  system,
  unknown,
}

class NotificationModel {
  final int id;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? payload;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.payload,
  });

  bool get isUnread => !isRead;

  NotificationModel copyWith({
    int? id,
    String? title,
    String? body,
    NotificationType? type,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? payload,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      payload: payload ?? this.payload,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final idRaw =
        json['notificationId'] ??
        json['NotificationId'] ??
        json['id'] ??
        json['Id'] ??
        0;

    final titleRaw = json['title'] ?? json['Title'] ?? '';

    final bodyRaw =
        json['description'] ??
        json['Description'] ??
        json['body'] ??
        json['message'] ??
        json['Body'] ??
        json['Message'] ??
        '';

    final createdAtRaw = json['createdAt'] ?? json['CreatedAt'];
    final payloadRaw = json['payload'] ?? json['Payload'];

    return NotificationModel(
      id: JsonHelpers.asInt(idRaw) ?? 0,
      title: titleRaw.toString().trim(),
      body: bodyRaw.toString().trim(),
      type: _parseType(json['type'] ?? json['Type']),
      isRead: JsonHelpers.asBool(json['isRead'] ?? json['IsRead']),
      createdAt: JsonHelpers.parseDateTime(createdAtRaw) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      payload: payloadRaw is Map<String, dynamic>
          ? payloadRaw
          : payloadRaw is Map
              ? Map<String, dynamic>.from(payloadRaw)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationId': id,
      'title': title,
      'description': body,
      'type': type.name,
      'isRead': isRead,
      'createdAt': createdAt.toUtc().toIso8601String(),
      if (payload != null) 'payload': payload,
    };
  }

  static NotificationType _parseType(dynamic raw) {
    if (raw == null) return NotificationType.unknown;

    final value = raw.toString().trim().toLowerCase();

    return switch (value) {
      'eventinvite' || 'event_invite' => NotificationType.eventInvite,

      'eventupdated' ||
      'eventupdate' ||
      'event_updated' ||
      'event_update' =>
        NotificationType.eventUpdate,

      'eventcancelled' ||
      'eventcanceled' ||
      'event_cancelled' ||
      'event_canceled' =>
        NotificationType.eventCancelled,

      'newfollower' || 'new_follower' => NotificationType.newFollower,

      'ticketpurchased' ||
      'ticketconfirmed' ||
      'ticket_confirmed' =>
        NotificationType.ticketConfirmed,

      'ticketcancelled' ||
      'ticketcanceled' ||
      'ticket_cancelled' ||
      'ticket_canceled' =>
        NotificationType.ticketCancelled,

      'newmessage' || 'message' => NotificationType.message,

      'welcome' ||
      'passwordreset' ||
      'accountbanned' ||
      'general' ||
      'system' ||
      'reservationconfirmed' ||
      'reservationexpired' ||
      'paymentsucceeded' ||
      'paymentfailed' ||
      'messageliked' ||
      'groupadded' ||
      'eventcommentliked' ||
      'eventcommentadded' ||
      'eventcommentreply' ||
      'eventliked' ||
      'eventbookmarked' ||
      'eventreservationcreated' ||
      'eventreservationpaid' =>
        NotificationType.system,

      _ => NotificationType.unknown,
    };
  }
}