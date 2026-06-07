import 'package:flutter/material.dart';

import '../../../../shared/payment/models/payment_method.dart';

class PaymentSubmitSection extends StatelessWidget {
  final double total;
  final String currency;
  final PaymentMethod method;
  final bool loading;
  final bool enabled;
  final VoidCallback onSubmit;

  const PaymentSubmitSection({
    super.key,
    required this.total,
    required this.currency,
    required this.method,
    required this.loading,
    required this.enabled,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final label = switch (method) {
      PaymentMethod.paypal => 'Pay ${formatPrice(total)} $currency with PayPal',
      PaymentMethod.cash => total <= 0
          ? 'Confirm cash reservation'
          : 'Reserve and pay cash',
    };

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: enabled && !loading ? onSubmit : null,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            : Text(label),
      ),
    );
  }

  String formatPrice(double value) => value.toStringAsFixed(2);
}