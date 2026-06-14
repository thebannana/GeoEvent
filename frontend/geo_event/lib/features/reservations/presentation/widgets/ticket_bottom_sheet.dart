import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/widgets/app_bottom_sheet_container.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../../../shared/reservations/models/ticket.dart';

class TicketBottomSheet extends StatelessWidget {
  final int reservationId;
  final String? eventTitle;
  final List<Ticket> tickets;

  const TicketBottomSheet({
    super.key,
    required this.reservationId,
    required this.tickets,
    this.eventTitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = (eventTitle ?? '').trim();

    return AppBottomSheetContainer(
      maxHeightFactor: 0.92,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 10, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tickets · Reservation #$reservationId',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (title.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: theme.dividerColor.withValues(alpha: 0.35),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
              itemCount: tickets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _TicketItem(
                ticket: tickets[i],
                eventTitle: title,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketItem extends StatelessWidget {
  final Ticket ticket;
  final String? eventTitle;

  const _TicketItem({
    required this.ticket,
    this.eventTitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dotColor = _ticketStatusColor(ticket.status);
    final title = (eventTitle ?? '').trim();

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.7),
                  ),
                ),
                padding: const EdgeInsets.all(6),
                child: QrImageView(
                  data: ticket.qrCode,
                  version: QrVersions.auto,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title.isNotEmpty) ...[
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      ticket.ticketType,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ticket #${ticket.ticketId}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (ticket.seatNumber != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Seat ${ticket.seatNumber}'
                        '${ticket.section != null ? ' · ${ticket.section}' : ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _StatusDot(color: dotColor),
                            const SizedBox(width: 5),
                            Text(
                              ticket.status,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${ticket.amount.toStringAsFixed(2)} ${ticket.currency}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.qr_code_2_rounded,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'QR value',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  ticket.qrCode,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    height: 1.35,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Use this code manually if scanning does not work.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;

  const _StatusDot({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

Color _ticketStatusColor(String status) {
  final normalized = status.toLowerCase();

  return switch (normalized) {
    'active' => const Color(0xFF437A22),
    'used' => const Color(0xFF006494),
    'cancelled' => const Color(0xFFA12C7B),
    'expired' => const Color(0xFF7A7974),
    'refunded' => const Color(0xFFD19900),
    _ => const Color(0xFF7A7974),
  };
}