import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_time_extensions.dart';
import '../../../../core/widgets/surfaces/app_surface_card.dart';
import '../../../../shared/reservations/models/reservation.dart';
import '../../../../shared/reservations/models/reservation_status.dart';
import '../../../../shared/reservations/providers/reservation_providers.dart';
import 'reservation_status_badge.dart';
import 'ticket_bottom_sheet.dart';

class ReservationCard extends ConsumerWidget {
  final Reservation reservation;
  final VoidCallback? onCancel;
  final VoidCallback? onRefund;

  const ReservationCard({
    super.key,
    required this.reservation,
    this.onCancel,
    this.onRefund,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = reservation.displayStatus;
    final canCancel = reservation.canBeCancelled && onCancel != null;
    final canRefund = reservation.canRequestRefund && onRefund != null;

    final eventAsync = ref.watch(reservationEventProvider(reservation.eventId));

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.confirmation_num_rounded,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your reservation',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      eventAsync.when(
                        data: (event) => Text(
                          event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        loading: () => Text(
                          'Loading event...',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        error: (_, _) => Text(
                          'Event details are currently unavailable',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ReservationStatusBadge(status: status),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: colorScheme.outline.withValues(alpha: 0.60),
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
                  label: reservation.createdAt.formatDate(
                    pattern: 'dd.MM.yyyy',
                  ),
                ),
              ],
            ),
          ),
          if (reservation.typedStatus == ReservationStatus.pending) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: colorScheme.error,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Expires ${reservation.expiresAt.formatDate(pattern: 'dd.MM.yyyy')}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (reservation.hasPendingRefundRequest) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Text(
                'Refund request submitted and waiting for admin review.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ] else if (reservation.isRefundRejected) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Text(
                reservation.refundDecisionReason?.trim().isNotEmpty == true
                    ? 'Refund request rejected: ${reservation.refundDecisionReason!.trim()}'
                    : 'Refund request was rejected.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ] else if (reservation.typedStatus == ReservationStatus.confirmed &&
              canRefund) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Text(
                'Need to cancel? Submit a refund request.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          if (reservation.typedStatus == ReservationStatus.refunded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Text(
                'Tickets from this reservation are no longer valid for entry.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (reservation.tickets.isNotEmpty || canCancel || canRefund)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (reservation.tickets.isNotEmpty)
                    TextButton.icon(
                      icon: const Icon(Icons.qr_code_rounded, size: 18),
                      label: Text(
                        '${reservation.tickets.length} ticket${reservation.tickets.length > 1 ? 's' : ''}',
                      ),
                      onPressed: () => _showTickets(
                        context,
                        eventAsync.valueOrNull?.title,
                      ),
                    ),
                  if (canCancel)
                    TextButton.icon(
                      icon: Icon(
                        Icons.cancel_outlined,
                        size: 18,
                        color: colorScheme.error,
                      ),
                      label: Text(
                        'Cancel',
                        style: TextStyle(color: colorScheme.error),
                      ),
                      onPressed: onCancel,
                    ),
                  if (canRefund)
                    TextButton.icon(
                      icon: Icon(
                        Icons.undo_rounded,
                        size: 18,
                        color: colorScheme.error,
                      ),
                      label: Text(
                        'Request refund',
                        style: TextStyle(color: colorScheme.error),
                      ),
                      onPressed: onRefund,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showTickets(BuildContext context, String? eventTitle) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TicketBottomSheet(
        // This is an internal value for application logic, not displayed here.
        reservationId: reservation.reservationId,
        eventTitle: eventTitle,
        tickets: reservation.tickets,
      ),
    );
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}