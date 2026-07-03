class PayPalApprovalResult {
  final bool approved;
  final String? orderId;
  final String? payerId;
  final String? error;

  const PayPalApprovalResult({
    required this.approved,
    this.orderId,
    this.payerId,
    this.error,
  });

  bool get hasValidApproval => approved && orderId != null && orderId!.trim().isNotEmpty;

  factory PayPalApprovalResult.approved({
    required String orderId,
    String? payerId,
  }) {
    return PayPalApprovalResult(
      approved: true,
      orderId: orderId.trim(),
      payerId: payerId?.trim(),
    );
  }

  factory PayPalApprovalResult.cancelled([String? error]) {
    return PayPalApprovalResult(
      approved: false,
      error: error?.trim(),
    );
  }
}