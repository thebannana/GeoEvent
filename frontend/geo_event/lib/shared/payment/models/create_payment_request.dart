import 'payment_method.dart';

class CreatePaymentRequest {
  final int eventId;
  final int quantity;
  final double subtotal;
  final double serviceFee;
  final double total;
  final PaymentMethod method;

  const CreatePaymentRequest({
    required this.eventId,
    required this.quantity,
    required this.subtotal,
    required this.serviceFee,
    required this.total,
    required this.method,
  });

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'quantity': quantity,
      'subtotal': subtotal,
      'serviceFee': serviceFee,
      'total': total,
      'paymentMethod': method.name,
    };
  }
}