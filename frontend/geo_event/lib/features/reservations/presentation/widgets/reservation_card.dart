import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_surface_card.dart';
import '../../../../shared/events/models/create_event_models.dart';
import '../../../../shared/events/providers/event_providers.dart';
import '../../../../shared/reservations/models/reservation.dart';
import 'reservation_status_badge.dart';
import 'ticket_bottom_sheet.dart';

final reservationEventProvider =
    FutureProvider.family<EventItem, int>((ref, eventId) async {
  return ref.read(eventsRepositoryProvider).getEventById(eventId);
});

class ReservationCard extends ConsumerWidget {
  final Reservation reservation;
  final VoidCallback onCancel;

  const ReservationCard({
    super.key,
    required this.reservation,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = reservation.displayStatus;
    final normalized = status.toLowerCase();
    final canCancel = reservation.canBeCancelled;

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
                        'Reservation #${reservation.reservationId}',
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
                        error: (_, __) => Text(
                          'Event #${reservation.eventId}',
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
                    color: colorScheme.error,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Expires ${_formatShortDate(reservation.expiresAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (reservation.tickets.isNotEmpty || canCancel)
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
                      onPressed: () =>
                          _showTickets(context, eventAsync.valueOrNull?.title),
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
        reservationId: reservation.reservationId,
        eventTitle: eventTitle,
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