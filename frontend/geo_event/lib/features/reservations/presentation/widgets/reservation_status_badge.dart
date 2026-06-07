import 'package:flutter/material.dart';

class ReservationStatusBadge extends StatelessWidget {
  final String status;

  const ReservationStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();

    final (color, bg) = switch (normalized) {
      'confirmed' => (
          const Color(0xFF437A22),
          const Color(0xFFD4DFCC),
        ),
      'pending' => (
          const Color(0xFFD19900),
          const Color(0xFFE9E0C6),
        ),
      'cancelled' => (
          const Color(0xFFA12C7B),
          const Color(0xFFE0CED7),
        ),
      'expired' => (
          const Color(0xFF7A7974),
          const Color(0xFFF0EFED),
        ),
      'refunded' => (
          const Color(0xFF006494),
          const Color(0xFFC6D8E4),
        ),
      _ => (
          const Color(0xFF7A7974),
          const Color(0xFFF0EFED),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}