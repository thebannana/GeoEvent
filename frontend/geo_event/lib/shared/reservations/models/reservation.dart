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
  });

  String get displayStatus {
    final normalized = status.trim().toLowerCase();
    final now = DateTime.now();

    if (normalized == 'cancelled') return 'Cancelled';
    if (normalized == 'refunded') return 'Refunded';
    if (normalized == 'expired') return 'Expired';

    if (expiresAt.isBefore(now) || expiresAt.isAtSameMomentAs(now)) {
      return 'Expired';
    }

    if (normalized == 'confirmed') return 'Confirmed';
    if (normalized == 'pending') return 'Pending';

    return _capitalize(status);
  }

  bool get isExpiredByTime {
    final now = DateTime.now();
    return expiresAt.isBefore(now) || expiresAt.isAtSameMomentAs(now);
  }

  bool get canBeCancelled {
    final normalized = displayStatus.toLowerCase();
    return normalized == 'pending' || normalized == 'confirmed';
  }

  bool get isActive {
    final normalized = displayStatus.toLowerCase();
    return normalized != 'cancelled' &&
        normalized != 'expired' &&
        normalized != 'refunded';
  }

  factory Reservation.fromJson(Map<String, dynamic> json) => Reservation(
        reservationId: (json['reservationId'] as num).toInt(),
        userId: (json['userId'] as num).toInt(),
        eventId: (json['eventId'] as num).toInt(),
        eventTicketId: (json['eventTicketId'] as num?)?.toInt(),
        quantity: (json['quantity'] as num).toInt(),
        totalAmount: (json['totalAmount'] as num).toDouble(),
        currency: (json['currency'] ?? '').toString(),
        status: (json['status'] ?? '').toString(),
        createdAt: DateTime.parse((json['createdAt'] ?? '').toString()).toLocal(),
        confirmedAt: json['confirmedAt'] != null
            ? DateTime.parse(json['confirmedAt'].toString()).toLocal()
            : null,
        cancelledAt: json['cancelledAt'] != null
            ? DateTime.parse(json['cancelledAt'].toString()).toLocal()
            : null,
        expiredAt: json['expiredAt'] != null
            ? DateTime.parse(json['expiredAt'].toString()).toLocal()
            : null,
        expiresAt: DateTime.parse((json['expiresAt'] ?? '').toString()).toLocal(),
        paymentReference: json['paymentReference']?.toString(),
        notes: json['notes']?.toString(),
        tickets: (json['tickets'] as List<dynamic>? ?? const [])
            .map((t) => Ticket.fromJson(Map<String, dynamic>.from(t as Map)))
            .toList(),
      );

  Reservation copyWith({
    int? reservationId,
    int? userId,
    int? eventId,
    Object? eventTicketId = _sentinel,
    int? quantity,
    double? totalAmount,
    String? currency,
    String? status,
    DateTime? createdAt,
    Object? confirmedAt = _sentinel,
    Object? cancelledAt = _sentinel,
    Object? expiredAt = _sentinel,
    DateTime? expiresAt,
    Object? paymentReference = _sentinel,
    Object? notes = _sentinel,
    List<Ticket>? tickets,
  }) {
    return Reservation(
      reservationId: reservationId ?? this.reservationId,
      userId: userId ?? this.userId,
      eventId: eventId ?? this.eventId,
      eventTicketId: identical(eventTicketId, _sentinel)
          ? this.eventTicketId
          : eventTicketId as int?,
      quantity: quantity ?? this.quantity,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: identical(confirmedAt, _sentinel)
          ? this.confirmedAt
          : confirmedAt as DateTime?,
      cancelledAt: identical(cancelledAt, _sentinel)
          ? this.cancelledAt
          : cancelledAt as DateTime?,
      expiredAt: identical(expiredAt, _sentinel)
          ? this.expiredAt
          : expiredAt as DateTime?,
      expiresAt: expiresAt ?? this.expiresAt,
      paymentReference: identical(paymentReference, _sentinel)
          ? this.paymentReference
          : paymentReference as String?,
      notes: identical(notes, _sentinel) ? this.notes : notes as String?,
      tickets: tickets ?? this.tickets,
    );
  }

  static String _capitalize(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    return '${trimmed[0].toUpperCase()}${trimmed.substring(1).toLowerCase()}';
  }
}

const _sentinel = Object();