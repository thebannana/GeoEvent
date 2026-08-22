import '../../../core/utils/json_helpers.dart';

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
  final DateTime? validatedAt;
  final bool canCollectCash;
  final int totalTickets;
  final int validatedTicketCount;

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
    required this.validatedAt,
    required this.canCollectCash,
    required this.totalTickets,
    required this.validatedTicketCount,
  });

  factory OrganizerReservationDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return OrganizerReservationDto(
      reservationId: JsonHelpers.asInt(
            json['reservationId'],
          ) ??
          0,
      userId: JsonHelpers.asInt(
            json['userId'],
          ) ??
          0,
      eventId: JsonHelpers.asInt(
            json['eventId'],
          ) ??
          0,
      eventTicketId: JsonHelpers.asInt(
        json['eventTicketId'],
      ),
      quantity: JsonHelpers.asInt(
            json['quantity'],
          ) ??
          0,
      totalAmount: JsonHelpers.asDouble(
        json['totalAmount'],
      ),
      currency:
          json['currency']?.toString() ?? '',
      status:
          json['status']?.toString() ?? '',
      createdAt: JsonHelpers.parseDateTimeRequired(
        json['createdAt'],
        DateTime.fromMillisecondsSinceEpoch(
          0,
          isUtc: true,
        ),
      ),
      confirmedAt: JsonHelpers.parseDateTime(
        json['confirmedAt'],
      ),
      cancelledAt: JsonHelpers.parseDateTime(
        json['cancelledAt'],
      ),
      expiredAt: JsonHelpers.parseDateTime(
        json['expiredAt'],
      ),
      expiresAt: JsonHelpers.parseDateTimeRequired(
        json['expiresAt'],
        DateTime.fromMillisecondsSinceEpoch(
          0,
          isUtc: true,
        ),
      ),
      paymentReference:
          json['paymentReference']?.toString(),
      notes: json['notes']?.toString(),
      participantUsername:
          json['participantUsername']?.toString(),
      participantAvatarUrl:
          json['participantAvatarUrl']?.toString(),
      refundRequestStatus:
          json['refundRequestStatus']?.toString(),
      refundReason:
          json['refundReason']?.toString(),
      refundRequestedAt:
          JsonHelpers.parseDateTime(
        json['refundRequestedAt'],
      ),
      refundReviewedAt:
          JsonHelpers.parseDateTime(
        json['refundReviewedAt'],
      ),
      refundReviewedByUserId:
          JsonHelpers.asInt(
        json['refundReviewedByUserId'],
      ),
      refundDecisionReason:
          json['refundDecisionReason']?.toString(),
      paymentMethod:
          json['paymentMethod']?.toString(),
      paymentStatus:
          json['paymentStatus']?.toString(),
      paymentMessage:
          json['paymentMessage']?.toString(),
      validatedAt: JsonHelpers.parseDateTime(
        json['validatedAt'],
      ),
      canCollectCash: JsonHelpers.asBool(
        json['canCollectCash'],
      ),
      totalTickets: JsonHelpers.asInt(
            json['totalTickets'],
          ) ??
          1,
      validatedTicketCount: JsonHelpers.asInt(
            json['validatedTicketCount'],
          ) ??
          0,
    );
  }

  bool get hasPendingRefundRequest =>
      (refundRequestStatus ?? '')
          .trim()
          .toLowerCase() ==
      'pending';

  bool get isRefundRejected =>
      (refundRequestStatus ?? '')
          .trim()
          .toLowerCase() ==
      'rejected';

  bool get isRefundCompleted =>
      (refundRequestStatus ?? '')
              .trim()
              .toLowerCase() ==
          'refunded' ||
      status.trim().toLowerCase() ==
          'refunded';

  bool get isCashPending =>
      (paymentMethod ?? '')
              .trim()
              .toLowerCase() ==
          'cash' &&
      (paymentStatus ?? '')
              .trim()
              .toLowerCase() ==
          'pending';

    bool get isCashCollected =>
      (paymentMethod ?? '').trim().toLowerCase() == 'cash' &&
      (paymentStatus ?? '').trim().toLowerCase() == 'completed';

  bool get isPayPalPaid =>
      (paymentMethod ?? '')
              .trim()
              .toLowerCase() ==
          'paypal' &&
      (paymentStatus ?? '')
              .trim()
              .toLowerCase() ==
          'completed';

  bool get allTicketsValidated =>
      totalTickets > 0 &&
      validatedTicketCount >= totalTickets;

  bool get hasPartialValidation =>
      validatedTicketCount > 0 &&
      validatedTicketCount < totalTickets;
}