import 'package:flutter/material.dart';

import '../../../../core/utils/price_formatter.dart';

class EventPriceBadge extends StatelessWidget {
  final double price;

  const EventPriceBadge({
    super.key,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isFree = price <= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isFree
            ? scheme.primary.withValues(alpha: 0.10)
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isFree
              ? scheme.primary.withValues(alpha: 0.28)
              : scheme.outline.withValues(alpha: 0.20),
        ),
      ),
      child: Text(
        isFree
            ? 'Free'
            : PriceFormatter.format(
                price,
                currency: PriceFormatter.bam,
                decimalDigits: price % 1 == 0 ? 0 : 2,
                fallback: '-',
              ),
        style: theme.textTheme.labelLarge?.copyWith(
          color: isFree ? scheme.primary : scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}