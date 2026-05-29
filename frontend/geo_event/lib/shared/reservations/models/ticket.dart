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

  factory Ticket.fromJson(Map<String, dynamic> json) => Ticket(
        ticketId: json['ticketId'] as int,
        reservationId: json['reservationId'] as int,
        userId: json['userId'] as int,
        eventId: json['eventId'] as int,
        ticketType: json['ticketType'] as String,
        qrCode: json['qrCode'] as String,
        amount: (json['amount'] as num).toDouble(),
        currency: json['currency'] as String,
        status: json['status'] as String,
        issuedAt: DateTime.parse(json['issuedAt'] as String),
        usedAt: json['usedAt'] != null
            ? DateTime.parse(json['usedAt'] as String)
            : null,
        cancelledAt: json['cancelledAt'] != null
            ? DateTime.parse(json['cancelledAt'] as String)
            : null,
        seatNumber: json['seatNumber'] as String?,
        section: json['section'] as String?,
      );
}