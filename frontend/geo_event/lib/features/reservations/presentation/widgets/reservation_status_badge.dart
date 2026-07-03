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
  final normalized = status.trim().toLowerCase();

  switch (normalized) {
    case 'confirmed':
      return _ReservationStatusScheme(
        foreground: colorScheme.primary,
        background: colorScheme.primary.withValues(alpha: 0.12),
      );
    case 'pending':
      return _ReservationStatusScheme(
        foreground: colorScheme.tertiary,
        background: colorScheme.tertiary.withValues(alpha: 0.12),
      );
    case 'cancelled':
      return _ReservationStatusScheme(
        foreground: colorScheme.onErrorContainer,
        background: colorScheme.errorContainer,
      );
    case 'expired':
      return _ReservationStatusScheme(
        foreground: colorScheme.onSurfaceVariant,
        background: colorScheme.surfaceContainerHighest,
      );
    case 'refunded':
      return _ReservationStatusScheme(
        foreground: colorScheme.onErrorContainer,
        background: colorScheme.errorContainer,
      );
    default:
      return _ReservationStatusScheme(
        foreground: colorScheme.onSurfaceVariant,
        background: colorScheme.surfaceContainerHighest,
      );
  }
}