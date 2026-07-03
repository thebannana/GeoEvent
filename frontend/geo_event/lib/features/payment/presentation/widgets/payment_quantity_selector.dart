import 'package:flutter/material.dart';

import '../../../../core/widgets/surfaces/app_surface_card.dart';

class PaymentQuantitySelector extends StatelessWidget {
  final int quantity;
  final int maxQuantity;
  final ValueChanged<int> onChanged;

  const PaymentQuantitySelector({
    super.key,
    required this.quantity,
    required this.maxQuantity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canDecrease = quantity > 1;
    final canIncrease = quantity < maxQuantity;

    return AppSurfaceCard(
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 12,
        spacing: 12,
        children: [
          SizedBox(
            width: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ticket quantity',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  maxQuantity <= 1
                      ? 'Only one ticket is currently available.'
                      : 'Choose how many tickets you want to reserve.',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: canDecrease ? () => onChanged(quantity - 1) : null,
                icon: const Icon(Icons.remove_circle_outline),
                tooltip: canDecrease
                    ? 'Decrease quantity'
                    : 'Minimum quantity reached',
              ),
              Text(
                '$quantity',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              IconButton(
                onPressed: canIncrease ? () => onChanged(quantity + 1) : null,
                icon: const Icon(Icons.add_circle_outline),
                tooltip: canIncrease
                    ? 'Increase quantity'
                    : 'Maximum available quantity reached',
              ),
            ],
          ),
        ],
      ),
    );
  }
}