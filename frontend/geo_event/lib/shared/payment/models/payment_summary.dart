class PaymentSummary {
  final int eventId;
  final String eventTitle;
  final String? eventImageUrl;
  final int eventTicketId;
  final String ticketType;
  final double unitPrice;
  final int quantity;
  final double serviceFee;
  final String currency;
  final String? ownerName;
  final String? categoryName;
  final String? eventDescription;

  const PaymentSummary({
    required this.eventId,
    required this.eventTitle,
    required this.eventImageUrl,
    required this.eventTicketId,
    required this.ticketType,
    required this.unitPrice,
    required this.quantity,
    required this.serviceFee,
    required this.currency,
    this.ownerName,
    this.categoryName,
    this.eventDescription,
  });

  double get subtotal => unitPrice * quantity;
  double get total => subtotal + serviceFee;
  bool get isFree => subtotal <= 0;

  PaymentSummary copyWith({
    int? quantity,
    double? unitPrice,
    double? serviceFee,
    String? ownerName,
    String? categoryName,
    String? eventDescription,
  }) {
    return PaymentSummary(
      eventId: eventId,
      eventTitle: eventTitle,
      eventImageUrl: eventImageUrl,
      eventTicketId: eventTicketId,
      ticketType: ticketType,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      serviceFee: serviceFee ?? this.serviceFee,
      currency: currency,
      ownerName: ownerName ?? this.ownerName,
      categoryName: categoryName ?? this.categoryName,
      eventDescription: eventDescription ?? this.eventDescription,
    );
  }
}