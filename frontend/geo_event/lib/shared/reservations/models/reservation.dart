import '../../tickets/models/request_refund_status.dart';
import 'reservation_status.dart';
import 'ticket.dart';

class Reservation {
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
  final List<Ticket> tickets;

  final String? refundRequestStatus;
  final String? refundReason;
  final DateTime? refundRequestedAt;
  final DateTime? refundReviewedAt;
  final int? refundReviewedByUserId;
  final String? refundDecisionReason;

  const Reservation({
    required this.reservationId,
    required this.userId,
    required this.eventId,
    this.eventTicketId,
    required this.quantity,
    required this.totalAmount,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.confirmedAt,
    this.cancelledAt,
    this.expiredAt,
    required this.expiresAt,
    this.paymentReference,
    this.notes,
    required this.tickets,
    this.refundRequestStatus,
    this.refundReason,
    this.refundRequestedAt,
    this.refundReviewedAt,
    this.refundReviewedByUserId,
    this.refundDecisionReason,
  });

  ReservationStatus get typedStatus {
  final normalized = status.trim().toLowerCase();
  final now = DateTime.now();

  if (normalized == ReservationStatus.cancelled.apiValue.toLowerCase()) {
    return ReservationStatus.cancelled;
  }

  if (normalized == ReservationStatus.refunded.apiValue.toLowerCase()) {
    return ReservationStatus.refunded;
  }

  if (normalized == ReservationStatus.expired.apiValue.toLowerCase()) {
    return ReservationStatus.expired;
  }

  if (normalized == ReservationStatus.confirmed.apiValue.toLowerCase()) {
    return ReservationStatus.confirmed;
  }

  if (normalized == ReservationStatus.pending.apiValue.toLowerCase()) {
    if (expiresAt.isBefore(now) || expiresAt.isAtSameMomentAs(now)) {
      return ReservationStatus.expired;
    }

    return ReservationStatus.pending;
  }

  return ReservationStatus.unknown;
}

String get displayStatus {
  switch (typedStatus) {
    case ReservationStatus.pending:
      return 'Pending';
    case ReservationStatus.confirmed:
      return 'Confirmed';
    case ReservationStatus.cancelled:
      return 'Cancelled';
    case ReservationStatus.expired:
      return 'Expired';
    case ReservationStatus.refunded:
      return 'Refunded';
    case ReservationStatus.unknown:
      return 'Unknown';
  }
}

  bool get isExpiredByTime {
    if (typedStatus != ReservationStatus.pending) {
      return false;
    }

    final now = DateTime.now();
    return expiresAt.isBefore(now) || expiresAt.isAtSameMomentAs(now);
  }

bool get canBeCancelled {
  if (typedStatus == ReservationStatus.pending) return true;
  if (typedStatus == ReservationStatus.confirmed && totalAmount <= 0) return true;
  return false;
}

bool get canBeRefunded {
  return typedStatus == ReservationStatus.confirmed && totalAmount > 0;
}

RefundRequestStatus get typedRefundStatus =>
    RefundRequestStatus.fromValue(refundRequestStatus);

bool get hasPendingRefundRequest =>
    typedRefundStatus == RefundRequestStatus.pending;

bool get isRefundRejected =>
    typedRefundStatus == RefundRequestStatus.rejected;

bool get isRefundCompleted =>
    typedRefundStatus == RefundRequestStatus.refunded ||
    typedStatus == ReservationStatus.refunded;

bool get canRequestRefund {
  return typedStatus == ReservationStatus.confirmed &&
      totalAmount > 0 &&
      typedRefundStatus != RefundRequestStatus.pending &&
      typedRefundStatus != RefundRequestStatus.processing &&
      typedRefundStatus != RefundRequestStatus.approved &&
      typedRefundStatus != RefundRequestStatus.refunded;
}

  bool get isActive {
    return typedStatus != ReservationStatus.cancelled &&
        typedStatus != ReservationStatus.expired &&
        typedStatus != ReservationStatus.refunded;
  }

  factory Reservation.fromJson(Map<String, dynamic> json) {
  DateTime? tryParse(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  return Reservation(
    reservationId: (json['reservationId'] as num).toInt(),
    userId: (json['userId'] as num).toInt(),
    eventId: (json['eventId'] as num).toInt(),
    eventTicketId: (json['eventTicketId'] as num?)?.toInt(),
    quantity: (json['quantity'] as num).toInt(),
    totalAmount: (json['totalAmount'] as num).toDouble(),
    currency: (json['currency'] ?? '').toString(),
    status: (json['status'] ?? '').toString(),
    createdAt: DateTime.parse((json['createdAt'] ?? '').toString()).toLocal(),
    confirmedAt: tryParse(json['confirmedAt']),
    cancelledAt: tryParse(json['cancelledAt']),
    expiredAt: tryParse(json['expiredAt']),
    expiresAt: DateTime.parse((json['expiresAt'] ?? '').toString()).toLocal(),
    paymentReference: json['paymentReference']?.toString(),
    notes: json['notes']?.toString(),
    tickets: (json['tickets'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((t) => Ticket.fromJson(Map<String, dynamic>.from(t)))
        .toList(),
    refundRequestStatus: json['refundRequestStatus']?.toString(),
    refundReason: json['refundReason']?.toString(),
    refundRequestedAt: tryParse(json['refundRequestedAt']),
    refundReviewedAt: tryParse(json['refundReviewedAt']),
    refundReviewedByUserId: (json['refundReviewedByUserId'] as num?)?.toInt(),
    refundDecisionReason: json['refundDecisionReason']?.toString(),
  );
}

  Reservation copyWith({
  int? reservationId,
  int? userId,
  int? eventId,
  Object? eventTicketId = sentinel,
  int? quantity,
  double? totalAmount,
  String? currency,
  String? status,
  DateTime? createdAt,
  Object? confirmedAt = sentinel,
  Object? cancelledAt = sentinel,
  Object? expiredAt = sentinel,
  DateTime? expiresAt,
  Object? paymentReference = sentinel,
  Object? notes = sentinel,
  List<Ticket>? tickets,
  Object? refundRequestStatus = sentinel,
  Object? refundReason = sentinel,
  Object? refundRequestedAt = sentinel,
  Object? refundReviewedAt = sentinel,
  Object? refundReviewedByUserId = sentinel,
  Object? refundDecisionReason = sentinel,
}) {
  return Reservation(
    reservationId: reservationId ?? this.reservationId,
    userId: userId ?? this.userId,
    eventId: eventId ?? this.eventId,
    eventTicketId: identical(eventTicketId, sentinel)
        ? this.eventTicketId
        : eventTicketId as int?,
    quantity: quantity ?? this.quantity,
    totalAmount: totalAmount ?? this.totalAmount,
    currency: currency ?? this.currency,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    confirmedAt: identical(confirmedAt, sentinel)
        ? this.confirmedAt
        : confirmedAt as DateTime?,
    cancelledAt: identical(cancelledAt, sentinel)
        ? this.cancelledAt
        : cancelledAt as DateTime?,
    expiredAt: identical(expiredAt, sentinel)
        ? this.expiredAt
        : expiredAt as DateTime?,
    expiresAt: expiresAt ?? this.expiresAt,
    paymentReference: identical(paymentReference, sentinel)
        ? this.paymentReference
        : paymentReference as String?,
    notes: identical(notes, sentinel) ? this.notes : notes as String?,
    tickets: tickets ?? this.tickets,
    refundRequestStatus: identical(refundRequestStatus, sentinel)
        ? this.refundRequestStatus
        : refundRequestStatus as String?,
    refundReason: identical(refundReason, sentinel)
        ? this.refundReason
        : refundReason as String?,
    refundRequestedAt: identical(refundRequestedAt, sentinel)
        ? this.refundRequestedAt
        : refundRequestedAt as DateTime?,
    refundReviewedAt: identical(refundReviewedAt, sentinel)
        ? this.refundReviewedAt
        : refundReviewedAt as DateTime?,
    refundReviewedByUserId: identical(refundReviewedByUserId, sentinel)
        ? this.refundReviewedByUserId
        : refundReviewedByUserId as int?,
    refundDecisionReason: identical(refundDecisionReason, sentinel)
        ? this.refundDecisionReason
        : refundDecisionReason as String?,
  );
}

  static const sentinel = Object();
}