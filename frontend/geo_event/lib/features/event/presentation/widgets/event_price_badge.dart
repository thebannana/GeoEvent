import 'package:flutter/material.dart';

class EventPriceBadge extends StatelessWidget {
  final double price;

  const EventPriceBadge({
    super.key,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    final isFree = price <= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          colors: [Color(0xFF70B8FF), Color(0xFF2D6DAA)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        isFree ? 'Free' : '${price.toStringAsFixed(price % 1 == 0 ? 0 : 2)} BAM',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}