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
      ticketId: (json['ticketId'] as num).toInt(),
      reservationId: (json['reservationId'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      eventId: (json['eventId'] as num).toInt(),
      ticketType: (json['ticketType'] ?? '').toString(),
      qrCode: (json['qrCode'] ?? '').toString(),
      amount: (json['amount'] as num).toDouble(),
      currency: (json['currency'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      issuedAt: DateTime.parse((json['issuedAt'] ?? '').toString()).toLocal(),
      usedAt: json['usedAt'] != null
          ? DateTime.parse(json['usedAt'].toString()).toLocal()
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'].toString()).toLocal()
          : null,
      seatNumber: json['seatNumber']?.toString(),
      section: json['section']?.toString(),
    );
}