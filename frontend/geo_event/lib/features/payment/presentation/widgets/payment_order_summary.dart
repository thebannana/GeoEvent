import 'package:flutter/material.dart';

import '../../../../shared/payment/models/payment_summary.dart';

class PaymentOrderSummary extends StatelessWidget {
  final PaymentSummary summary;

  const PaymentOrderSummary({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF17191D) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF2A303A) : const Color(0xFFE5EAF2),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: summary.eventImageUrl != null &&
                    summary.eventImageUrl!.trim().isNotEmpty
                ? Image.network(
                    summary.eventImageUrl!,
                    width: 74,
                    height: 74,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _FallbackImage(),
                  )
                : _FallbackImage(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.eventTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${summary.quantity} ticket${summary.quantity > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 74,
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
      alignment: Alignment.center,
      child: Icon(
        Icons.confirmation_num_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}