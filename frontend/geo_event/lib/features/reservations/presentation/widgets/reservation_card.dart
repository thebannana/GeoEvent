import 'package:flutter/material.dart';

import '../../../../shared/reservations/models/reservation.dart';
import 'reservation_status_badge.dart';
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
    final normalized = status.toLowerCase();
    final canCancel = normalized == 'pending' || normalized == 'confirmed';

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
                ReservationStatusBadge(status: status),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            indent: 14,
            endIndent: 14,
            color:
                isDark ? const Color(0xFF2A303A) : const Color(0xFFE3EAF3),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DetailChip(
                  icon: Icons.confirmation_num_outlined,
                  label:
                      '${reservation.quantity} ticket${reservation.quantity > 1 ? 's' : ''}',
                ),
                _DetailChip(
                  icon: Icons.payments_outlined,
                  label:
                      '${reservation.totalAmount.toStringAsFixed(2)} ${reservation.currency}',
                ),
                _DetailChip(
                  icon: Icons.calendar_today_outlined,
                  label: _formatShortDate(reservation.createdAt),
                ),
              ],
            ),
          ),
          if (normalized == 'pending') ...[
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

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailChip({
    required this.icon,
    required this.label,
  });

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
          Icon(
            icon,
            size: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
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