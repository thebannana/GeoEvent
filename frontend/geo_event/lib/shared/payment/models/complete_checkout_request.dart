import 'payment_method.dart';

class CompleteCheckoutRequest {
  final int eventId;
  final int eventTicketId;
  final int quantity;
  final String currency;
  final String paymentReference;
  final PaymentMethod paymentMethod;
  final double amount;

  const CompleteCheckoutRequest({
    required this.eventId,
    required this.eventTicketId,
    required this.quantity,
    required this.currency,
    required this.paymentReference,
    required this.paymentMethod,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'eventTicketId': eventTicketId,
        'quantity': quantity,
        'currency': currency,
        'paymentReference': paymentReference,
        'paymentMethod': paymentMethod.apiValue,
        'amount': amount,
      };
}