import 'package:flutter/material.dart';

import '../../../../shared/payment/models/payment_method.dart';

class PaymentMethodSelector extends StatelessWidget {
  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onSelected;

  const PaymentMethodSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final methods = [PaymentMethod.paypal, PaymentMethod.cash];

    return Column(
      children: methods
          .map(
            (method) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PaymentMethodTile(
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

class _PaymentMethodTile extends StatelessWidget {
  final PaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withValues(alpha: 0.16)
              : isDark
                  ? const Color(0xFF1C1F24)
                  : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? primary.withValues(alpha: 0.55)
                : isDark
                    ? const Color(0xFF2D323A)
                    : const Color(0xFFE6EBF2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _iconFor(method),
              color: isSelected ? primary : theme.iconTheme.color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                method.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
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
    );
  }

  IconData _iconFor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.paypal:
        return Icons.account_balance_wallet_outlined;
      case PaymentMethod.cash:
        return Icons.attach_money_rounded;
    }
  }
}