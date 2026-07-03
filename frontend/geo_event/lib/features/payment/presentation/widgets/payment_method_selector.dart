import 'package:flutter/material.dart';

import '../../../../shared/payment/models/payment_method.dart';

class PaymentMethodSelector extends StatelessWidget {
  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onSelected;
  final bool isFree;

  const PaymentMethodSelector({
    super.key,
    required this.selected,
    required this.onSelected,
    this.isFree = false,
  });

  @override
  Widget build(BuildContext context) {
    final methods = isFree
        ? const <PaymentMethod>[]
        : const [PaymentMethod.paypal, PaymentMethod.cash];

    if (methods.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: methods
          .map(
            (method) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PaymentMethodTile(
                method: method,
                isSelected: selected == method,
                onTap: () => onSelected(method),
              ),
            ),
          )
          .toList(),
    );
  }
}

class PaymentMethodTile extends StatelessWidget {
  final PaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;

  const PaymentMethodTile({
    super.key,
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: isSelected
                ? primary.withValues(alpha: 0.16)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? primary.withValues(alpha: 0.55)
                  : colorScheme.outline.withValues(alpha: 0.75),
            ),
          ),
          child: Row(
            children: [
              Icon(
                iconFor(method),
                color: isSelected ? primary : theme.iconTheme.color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  method.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                size: 20,
                color: isSelected
                    ? primary
                    : theme.iconTheme.color?.withValues(alpha: 0.75),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData iconFor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.paypal:
        return Icons.account_balance_wallet_outlined;
      case PaymentMethod.cash:
        return Icons.payments_outlined;
    }
  }
}