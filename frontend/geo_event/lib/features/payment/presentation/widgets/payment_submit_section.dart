import 'package:flutter/material.dart';
import '../../../../core/widgets/feedback/app_spinner.dart';
import '../../../../shared/payment/models/payment_method.dart';

class PaymentSubmitSection extends StatelessWidget {
  final double total;
  final String currency;
  final PaymentMethod method;
  final bool loading;
  final bool enabled;
  final bool isFree;
  final Future<void> Function() onSubmit;

  const PaymentSubmitSection({
    super.key,
    required this.total,
    required this.currency,
    required this.method,
    required this.loading,
    required this.enabled,
    required this.isFree,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final label = isFree
        ? 'Confirm reservation'
        : method == PaymentMethod.paypal
            ? 'Proceed to PayPal'
            : 'Confirm cash reservation';

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: enabled && !loading ? () async => onSubmit() : null,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: loading
            ? const AppSpinner(
                size: 20,
                strokeWidth: 2.4,
                color: Colors.white,
              )
            : Text(label),
      ),
    );
  }
}