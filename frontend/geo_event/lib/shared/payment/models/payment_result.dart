class PaymentResult {
  final bool success;
  final String message;
  final int? reservationId;
  final String? paymentReference;

  const PaymentResult({
    required this.success,
    required this.message,
    this.reservationId,
    this.paymentReference,
  });

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String? ?? 'Payment completed successfully.',
      reservationId: (json['reservationId'] as num?)?.toInt(),
      paymentReference: json['paymentReference'] as String?,
    );
  }
}