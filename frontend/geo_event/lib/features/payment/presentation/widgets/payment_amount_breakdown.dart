import 'package:flutter/material.dart';
import 'package:geo_event/shared/payment/models/payment_summary.dart';

import '../../../../core/widgets/surfaces/app_surface_card.dart';

class PaymentAmountBreakdown extends StatelessWidget {
  final PaymentSummary summary;

  const PaymentAmountBreakdown({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String value, {bool strong = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: strong ? 14 : 13,
                  fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: strong ? 15 : 13,
                fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Amount breakdown',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          row('Subtotal', _formatPrice(summary.subtotal, summary.currency)),
          row('Service fee', _formatPrice(summary.serviceFee, summary.currency)),
          const Divider(height: 24),
          row(
            'Total',
            _formatPrice(summary.total, summary.currency),
            strong: true,
          ),
        ],
      ),
    );
  }

  String _formatPrice(double value, String currency) {
    return '${value.toStringAsFixed(2)} $currency';
  }
}