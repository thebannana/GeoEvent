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
  });

  factory OrganizerReservationDto.fromJson(Map<String, dynamic> json) {
    return OrganizerReservationDto(
      reservationId: (json['reservationId'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      eventId: (json['eventId'] as num).toInt(),
      eventTicketId: (json['eventTicketId'] as num?)?.toInt(),
      quantity: (json['quantity'] as num).toInt(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      currency: json['currency']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: DateTime.parse(json['createdAt'].toString()),
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.tryParse(json['confirmedAt'].toString())
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.tryParse(json['cancelledAt'].toString())
          : null,
      expiredAt: json['expiredAt'] != null
          ? DateTime.tryParse(json['expiredAt'].toString())
          : null,
      expiresAt: DateTime.parse(json['expiresAt'].toString()),
      paymentReference: json['paymentReference']?.toString(),
      notes: json['notes']?.toString(),
    );
  }
}