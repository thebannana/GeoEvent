import 'package:flutter/material.dart';

import '../../../../core/widgets/app_surface_card.dart';
import '../../../../shared/payment/models/payment_summary.dart';

class PaymentOrderSummary extends StatelessWidget {
  final PaymentSummary summary;

  const PaymentOrderSummary({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    errorBuilder: (_, __, ___) => const _FallbackImage(),
                  )
                : const _FallbackImage(),
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
  const _FallbackImage();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 74,
      height: 74,
      color: colorScheme.primary.withValues(alpha: 0.10),
      alignment: Alignment.center,
      child: Icon(
        Icons.confirmation_num_outlined,
        color: colorScheme.primary,
      ),
    );
  }
}