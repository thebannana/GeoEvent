import 'package:flutter/material.dart';

import '../../../../core/widgets/app_surface_card.dart';

class PaymentEventInfoCard extends StatelessWidget {
  final String? ownerName;
  final String? categoryName;
  final String? description;

  const PaymentEventInfoCard({
    super.key,
    this.ownerName,
    this.categoryName,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget row(String label, String? value) {
      if (value == null || value.trim().isEmpty) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 82,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value.trim(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
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
            'Event information',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          row('Organizer', ownerName),
          row('Category', categoryName),
          row('Details', description),
        ],
      ),
    );
  }
}