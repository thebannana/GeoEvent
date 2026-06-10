import 'package:flutter/material.dart';

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
    final success = result.status == 'valid';

    Color accent;
    IconData icon;

    switch (result.status) {
      case 'valid':
        accent = Colors.green;
        icon = Icons.verified_rounded;
        break;
      case 'already_used':
        accent = Colors.orange;
        icon = Icons.history_toggle_off_rounded;
        break;
      default:
        accent = colors.error;
        icon = Icons.cancel_rounded;
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: accent, size: 42),
            const SizedBox(height: 12),
            Text(
              result.message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundImage: (result.participantAvatarUrl ?? '').trim().isNotEmpty
                    ? NetworkImage(result.participantAvatarUrl!)
                    : null,
                child: (result.participantAvatarUrl ?? '').trim().isEmpty
                    ? const Icon(Icons.person_rounded)
                    : null,
              ),
              title: Text(result.participantUsername ?? 'Unknown attendee'),
              subtitle: Text(result.ticketType ?? 'Ticket'),
            ),
            if (result.usedAt != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time_rounded),
                title: const Text('Previously used'),
                subtitle: Text(result.usedAt!.toLocal().toString()),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(success ? 'Continue scanning' : 'Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}