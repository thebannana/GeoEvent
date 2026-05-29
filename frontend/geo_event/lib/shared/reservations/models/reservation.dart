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

  factory Reservation.fromJson(Map<String, dynamic> json) => Reservation(
        reservationId: json['reservationId'] as int,
        userId: json['userId'] as int,
        eventId: json['eventId'] as int,
        eventTicketId: json['eventTicketId'] as int?,
        quantity: json['quantity'] as int,
        totalAmount: (json['totalAmount'] as num).toDouble(),
        currency: json['currency'] as String,
        status: json['status'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        confirmedAt: json['confirmedAt'] != null
            ? DateTime.parse(json['confirmedAt'] as String)
            : null,
        cancelledAt: json['cancelledAt'] != null
            ? DateTime.parse(json['cancelledAt'] as String)
            : null,
        expiredAt: json['expiredAt'] != null
            ? DateTime.parse(json['expiredAt'] as String)
            : null,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        paymentReference: json['paymentReference'] as String?,
        notes: json['notes'] as String?,
        tickets: (json['tickets'] as List<dynamic>? ?? [])
            .map((t) => Ticket.fromJson(t as Map<String, dynamic>))
            .toList(),
      );
}