enum TicketStatus {
  active,
  used,
  cancelled,
  expired,
  refunded,
}

class Ticket {
  final int ticketId;
  final int reservationId;
  final int userId;
  final int eventId;
  final String ticketType;
  final String qrCode;
  final double amount;
  final String currency;
  final String status;
  final DateTime issuedAt;
  final DateTime? usedAt;
  final DateTime? cancelledAt;
  final String? seatNumber;
  final String? section;

  const Ticket({
    required this.ticketId,
    required this.reservationId,
    required this.userId,
    required this.eventId,
    required this.ticketType,
    required this.qrCode,
    required this.amount,
    required this.currency,
    required this.status,
    required this.issuedAt,
    this.usedAt,
    this.cancelledAt,
    this.seatNumber,
    this.section,
  });

  TicketStatus get typedStatus {
    final normalized = status.trim().toLowerCase();

    if (cancelledAt != null || normalized == 'cancelled') {
      return TicketStatus.cancelled;
    }

    if (usedAt != null || normalized == 'used') {
      return TicketStatus.used;
    }

    if (normalized == 'refunded') {
      return TicketStatus.refunded;
    }

    if (normalized == 'expired') {
      return TicketStatus.expired;
    }

    return TicketStatus.active;
  }

  String get displayStatus {
    switch (typedStatus) {
      case TicketStatus.active:
        return 'Active';
      case TicketStatus.used:
        return 'Used';
      case TicketStatus.cancelled:
        return 'Cancelled';
      case TicketStatus.expired:
        return 'Expired';
      case TicketStatus.refunded:
        return 'Refunded';
    }
  }

  bool get isUsable => typedStatus == TicketStatus.active;

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      ticketId: (json['ticketId'] as num).toInt(),
      reservationId: (json['reservationId'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      eventId: (json['eventId'] as num).toInt(),
      ticketType: (json['ticketType'] ?? '').toString(),
      qrCode: (json['qrCode'] ?? '').toString(),
      amount: (json['amount'] as num).toDouble(),
      currency: (json['currency'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      issuedAt: DateTime.parse((json['issuedAt'] ?? '').toString()).toUtc(),
      usedAt: json['usedAt'] != null
          ? DateTime.parse(json['usedAt'].toString()).toUtc()
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'].toString()).toUtc()
          : null,
      seatNumber: json['seatNumber']?.toString(),
      section: json['section']?.toString(),
    );
  }
}