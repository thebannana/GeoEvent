enum PaymentMethod {
  paypal('PayPal', 'PayPal'),
  cash('Cash', 'Cash');

  final String label;
  final String apiValue;

  const PaymentMethod(this.label, this.apiValue);

  bool get isPayPal => this == PaymentMethod.paypal;
  bool get isCash => this == PaymentMethod.cash;
}