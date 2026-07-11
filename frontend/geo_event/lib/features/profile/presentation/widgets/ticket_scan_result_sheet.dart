import 'package:flutter/material.dart';

import '../../../../core/utils/date_time_extensions.dart';
import '../../../../core/widgets/layout/app_bottom_sheet_container.dart';
import '../../../../shared/profile/models/ticket_scan_result.dart';

class TicketScanResultSheet extends StatelessWidget {
  final TicketScanResultDto result;

  const TicketScanResultSheet({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = result.status.trim().toLowerCase();

    Color accent;
    IconData icon;
    String actionLabel;

    switch (status) {
      case 'valid':
        accent = Colors.green;
        icon = Icons.verified_rounded;
        actionLabel = 'Continue scanning';
        break;
      case 'already_used':
        accent = Colors.orange;
        icon = Icons.history_toggle_off_rounded;
        actionLabel = 'Close';
        break;
      default:
        accent = colors.error;
        icon = Icons.cancel_rounded;
        actionLabel = 'Close';
    }

    final hasAvatar = (result.participantAvatarUrl ?? '').trim().isNotEmpty;
    final participantName = (result.participantUsername ?? '').trim().isNotEmpty
        ? result.participantUsername!.trim()
        : 'Unknown attendee';
    final ticketType = (result.ticketType ?? '').trim().isNotEmpty
        ? result.ticketType!.trim()
        : 'Ticket';

    return AppBottomSheetContainer(
      scrollable: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accent, size: 42),
          const SizedBox(height: 12),
          Text(
            result.message.trim().isNotEmpty
                ? result.message.trim()
                : 'Ticket status processed.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundImage: hasAvatar
                  ? NetworkImage(result.participantAvatarUrl!.trim())
                  : null,
              child: hasAvatar ? null : const Icon(Icons.person_rounded),
            ),
            title: Text(participantName),
            subtitle: Text(ticketType),
          ),
          if ((result.paymentMessage ?? '').trim().isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _paymentInfoBackground(),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _paymentInfoBorder()),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _paymentInfoIcon(),
                    size: 18,
                    color: _paymentInfoColor(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      result.paymentMessage!.trim(),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _paymentInfoColor(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (result.scannedAt != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.qr_code_scanner_rounded),
              title: const Text('Scanned at'),
              subtitle: Text(
                result.scannedAt!.formatDateTime(
                  pattern: 'dd.MM.yyyy • HH:mm',
                ),
              ),
            ),
          if (result.usedAt != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time_rounded),
              title: const Text('Previously used'),
              subtitle: Text(
                result.usedAt!.formatDateTime(
                  pattern: 'dd.MM.yyyy • HH:mm',
                ),
              ),
            ),
          if (result.paymentMethod != null || result.paymentStatus != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.payments_outlined),
              title: const Text('Payment'),
              subtitle: Text(_paymentSummary()),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }

  bool get _isCashPending =>
      (result.paymentMethod ?? '').trim().toLowerCase() == 'cash' &&
      (result.paymentStatus ?? '').trim().toLowerCase() == 'pending';

  Color _paymentInfoBackground() {
    if (_isCashPending) {
      return Colors.amber.withValues(alpha: 0.14);
    }
    return Colors.green.withValues(alpha: 0.10);
  }

  Color _paymentInfoBorder() {
    if (_isCashPending) {
      return Colors.amber.withValues(alpha: 0.35);
    }
    return Colors.green.withValues(alpha: 0.25);
  }

  Color _paymentInfoColor() {
    if (_isCashPending) {
      return Colors.orange.shade900;
    }
    return Colors.green.shade800;
  }

  IconData _paymentInfoIcon() {
    if (_isCashPending) {
      return Icons.schedule_rounded;
    }
    return Icons.verified_rounded;
  }

  String _paymentSummary() {
    final method = (result.paymentMethod ?? '').trim();
    final status = (result.paymentStatus ?? '').trim();

    if (method.isEmpty && status.isEmpty) return 'Unavailable';
    if (method.isEmpty) return status;
    if (status.isEmpty) return method;
    return '$method • $status';
  }
}