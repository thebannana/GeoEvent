enum PaymentMethod {
  paypal('PayPal', 'PayPal'),
  cash('Cash', 'Cash');

  final String label;
  final String apiValue;

  const PaymentMethod(this.label, this.apiValue);
}