import 'package:flutter/material.dart';

import '../../../../shared/reservations/models/reservation.dart';
import 'ticket_bottom_sheet.dart';

class ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback onCancel;

  const ReservationCard({
    super.key,
    required this.reservation,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final status = reservation.status;
    final canCancel = status == 'Pending' || status == 'Confirmed';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2028) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2A303A) : const Color(0xFFE3EAF3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.10 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF222833)
                        : const Color(0xFFF3F6FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.confirmation_num_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reservation #${reservation.reservationId}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Event #${reservation.eventId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Divider(
            height: 1,
            indent: 14,
            endIndent: 14,
            color: isDark
                ? const Color(0xFF2A303A)
                : const Color(0xFFE3EAF3),
          ),

          // ── Details ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                _DetailChip(
                  icon: Icons.confirmation_num_outlined,
                  label:
                      '${reservation.quantity} ticket${reservation.quantity > 1 ? 's' : ''}',
                ),
                const SizedBox(width: 8),
                _DetailChip(
                  icon: Icons.payments_outlined,
                  label:
                      '${reservation.totalAmount.toStringAsFixed(2)} ${reservation.currency}',
                ),
                const SizedBox(width: 8),
                _DetailChip(
                  icon: Icons.calendar_today_outlined,
                  label: _formatShortDate(reservation.createdAt),
                ),
              ],
            ),
          ),

          // ── Expiry warning for pending ───────────────────────────────
          if (status == 'Pending') ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Expires ${_formatShortDate(reservation.expiresAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Actions ─────────────────────────────────────────────────
          if (reservation.tickets.isNotEmpty || canCancel)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Row(
                children: [
                  if (reservation.tickets.isNotEmpty)
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.qr_code_rounded, size: 18),
                        label: Text(
                          '${reservation.tickets.length} ticket${reservation.tickets.length > 1 ? 's' : ''}',
                        ),
                        onPressed: () => _showTickets(context),
                      ),
                    ),
                  if (canCancel)
                    Expanded(
                      child: TextButton.icon(
                        icon: Icon(
                          Icons.cancel_outlined,
                          size: 18,
                          color: theme.colorScheme.error,
                        ),
                        label: Text(
                          'Cancel',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                        onPressed: onCancel,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showTickets(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => TicketBottomSheet(
        reservationId: reservation.reservationId,
        tickets: reservation.tickets,
      ),
    );
  }

  String _formatShortDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.'
        '${local.month.toString().padLeft(2, '0')}.'
        '${local.year}';
  }
}

// ── Status badge ───────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (status) {
      'Confirmed' => (
          const Color(0xFF437A22),
          const Color(0xFFD4DFCC),
        ),
      'Pending' => (
          const Color(0xFFD19900),
          const Color(0xFFE9E0C6),
        ),
      'Cancelled' => (
          const Color(0xFFA12C7B),
          const Color(0xFFE0CED7),
        ),
      'Expired' => (
          const Color(0xFF7A7974),
          const Color(0xFFF0EFED),
        ),
      'Refunded' => (
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

// ── Detail chip ────────────────────────────────────────────────────────────

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DetailChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222833) : const Color(0xFFF3F6FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}