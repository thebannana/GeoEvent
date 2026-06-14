import 'package:flutter/material.dart';

class ReservationStatusBadge extends StatelessWidget {
  final String status;

  const ReservationStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = _reservationStatusScheme(context, status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: scheme.foreground,
        ),
      ),
    );
  }
}

class _ReservationStatusScheme {
  final Color foreground;
  final Color background;

  const _ReservationStatusScheme({
    required this.foreground,
    required this.background,
  });
}

_ReservationStatusScheme _reservationStatusScheme(
  BuildContext context,
  String status,
) {
  final colorScheme = Theme.of(context).colorScheme;
  final normalized = status.toLowerCase();

  return switch (normalized) {
    'confirmed' => _ReservationStatusScheme(
        foreground: colorScheme.primary,
        background: colorScheme.primary.withValues(alpha: 0.12),
      ),
    'pending' => _ReservationStatusScheme(
        foreground: const Color(0xFFD19900),
        background: const Color(0xFFE9E0C6),
      ),
    'cancelled' => _ReservationStatusScheme(
        foreground: colorScheme.onErrorContainer,
        background: colorScheme.errorContainer,
      ),
    'expired' => _ReservationStatusScheme(
        foreground: colorScheme.onSurfaceVariant,
        background: colorScheme.surfaceContainerHighest,
      ),
    'refunded' => _ReservationStatusScheme(
        foreground: const Color(0xFF006494),
        background: const Color(0xFFC6D8E4),
      ),
    _ => _ReservationStatusScheme(
        foreground: colorScheme.onSurfaceVariant,
        background: colorScheme.surfaceContainerHighest,
      ),
  };
}