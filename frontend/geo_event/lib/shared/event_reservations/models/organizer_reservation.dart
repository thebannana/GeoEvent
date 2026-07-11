class OrganizerReservationDto {
  final int reservationId;
  final int userId;
  final int eventId;
  final int? eventTicketId;
  final int quantity;
  final double totalAmount;
  final String currency;
  final String status;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;
  final DateTime? expiredAt;
  final DateTime expiresAt;
  final String? paymentReference;
  final String? notes;
  final String? participantUsername;
  final String? participantAvatarUrl;
  final String? refundRequestStatus;
  final String? refundReason;
  final DateTime? refundRequestedAt;
  final DateTime? refundReviewedAt;
  final int? refundReviewedByUserId;
  final String? refundDecisionReason;

  final String? paymentMethod;
  final String? paymentStatus;
  final String? paymentMessage;
  final bool hasIssuedTickets;
  final bool hasValidatedTicket;
  final DateTime? validatedAt;
  final bool canCollectCash;

  const OrganizerReservationDto({
    required this.reservationId,
    required this.userId,
    required this.eventId,
    required this.eventTicketId,
    required this.quantity,
    required this.totalAmount,
    required this.currency,
    required this.status,
    required this.createdAt,
    required this.confirmedAt,
    required this.cancelledAt,
    required this.expiredAt,
    required this.expiresAt,
    required this.paymentReference,
    required this.notes,
    this.participantUsername,
    this.participantAvatarUrl,
    this.refundRequestStatus,
    this.refundReason,
    this.refundRequestedAt,
    this.refundReviewedAt,
    this.refundReviewedByUserId,
    this.refundDecisionReason,
    this.paymentMethod,
    this.paymentStatus,
    this.paymentMessage,
    required this.hasIssuedTickets,
    required this.hasValidatedTicket,
    required this.validatedAt,
    required this.canCollectCash,
  });

  factory OrganizerReservationDto.fromJson(Map<String, dynamic> json) {
    DateTime? tryParse(dynamic value) {
      if (value == null) return null;
      final raw = value.toString().trim();
      if (raw.isEmpty) return null;
      return DateTime.tryParse(raw)?.toLocal();
    }

    bool readBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      final raw = value?.toString().trim().toLowerCase();
      return raw == 'true' || raw == '1';
    }

    return OrganizerReservationDto(
      reservationId: (json['reservationId'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      eventId: (json['eventId'] as num).toInt(),
      eventTicketId: (json['eventTicketId'] as num?)?.toInt(),
      quantity: (json['quantity'] as num).toInt(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      currency: json['currency']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: DateTime.parse(json['createdAt'].toString()).toLocal(),
      confirmedAt: tryParse(json['confirmedAt']),
      cancelledAt: tryParse(json['cancelledAt']),
      expiredAt: tryParse(json['expiredAt']),
      expiresAt: DateTime.parse(json['expiresAt'].toString()).toLocal(),
      paymentReference: json['paymentReference']?.toString(),
      notes: json['notes']?.toString(),
      participantUsername: json['participantUsername']?.toString(),
      participantAvatarUrl: json['participantAvatarUrl']?.toString(),
      refundRequestStatus: json['refundRequestStatus']?.toString(),
      refundReason: json['refundReason']?.toString(),
      refundRequestedAt: tryParse(json['refundRequestedAt']),
      refundReviewedAt: tryParse(json['refundReviewedAt']),
      refundReviewedByUserId: (json['refundReviewedByUserId'] as num?)?.toInt(),
      refundDecisionReason: json['refundDecisionReason']?.toString(),
      paymentMethod: json['paymentMethod']?.toString(),
      paymentStatus: json['paymentStatus']?.toString(),
      paymentMessage: json['paymentMessage']?.toString(),
      hasIssuedTickets: readBool(json['hasIssuedTickets']),
      hasValidatedTicket: readBool(json['hasValidatedTicket']),
      validatedAt: tryParse(json['validatedAt']),
      canCollectCash: readBool(json['canCollectCash']),
    );
  }

  bool get hasPendingRefundRequest =>
      (refundRequestStatus ?? '').trim().toLowerCase() == 'pending';

  bool get isRefundRejected =>
      (refundRequestStatus ?? '').trim().toLowerCase() == 'rejected';

  bool get isRefundCompleted =>
      (refundRequestStatus ?? '').trim().toLowerCase() == 'refunded' ||
      status.trim().toLowerCase() == 'refunded';

  bool get isCashPending =>
      (paymentMethod ?? '').trim().toLowerCase() == 'cash' &&
      (paymentStatus ?? '').trim().toLowerCase() == 'pending';

  bool get isPayPalPaid =>
      (paymentMethod ?? '').trim().toLowerCase() == 'paypal' &&
      (paymentStatus ?? '').trim().toLowerCase() == 'completed';

bool get isValidated => hasValidatedTicket || validatedAt != null;
}