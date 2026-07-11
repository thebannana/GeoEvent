import 'package:flutter/material.dart';

import '../../../../core/constants/event_status.dart';
import '../../../../core/utils/date_time_extensions.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/widgets/feedback/app_spinner.dart';
import '../../../../core/widgets/inputs/app_chip.dart';
import '../../../../core/widgets/surfaces/app_surface_card.dart';
import '../../../../shared/my_events/models/my_event_response_dto.dart';

enum MyEventMenuAction {
  edit,
  reservations,
  delete,
}

class MyEventCard extends StatelessWidget {
  const MyEventCard({
    super.key,
    required this.event,
    required this.actionsDisabled,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onViewReservations,
  });

  final MyEventResponseDto event;
  final bool actionsDisabled;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onViewReservations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = event.displayStatus;
    final statusColor = EventStatus.displayColor(status);

    return AppSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyEventCardImage(imageUrl: event.displayImageUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    PopupMenuButton<MyEventMenuAction>(
                      tooltip: 'Event actions',
                      onSelected: (value) {
                        switch (value) {
                          case MyEventMenuAction.edit:
                            onEdit?.call();
                            break;
                          case MyEventMenuAction.reservations:
                            if (!event.canViewReservations) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Reservations are not available for this event yet.',
                                  ),
                                ),
                              );
                              return;
                            }
                            onViewReservations?.call();
                            break;
                          case MyEventMenuAction.delete:
                            onDelete?.call();
                            break;
                        }
                      },
                      itemBuilder: (context) {
                        final disabledColor = Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.5);

                        return [
                          PopupMenuItem(
                            value: MyEventMenuAction.edit,
                            enabled: !actionsDisabled,
                            child: const _MyEventMenuRow(
                              icon: Icons.edit_rounded,
                              label: 'Edit',
                            ),
                          ),
                          PopupMenuItem(
                            value: MyEventMenuAction.reservations,
                            enabled: !actionsDisabled && event.canViewReservations,
                            child: _MyEventMenuRow(
                              icon: Icons.groups_rounded,
                              label: event.canViewReservations
                                  ? 'View reservations'
                                  : 'View reservations unavailable',
                              color: (!actionsDisabled && event.canViewReservations)
                                  ? null
                                  : disabledColor,
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: MyEventMenuAction.delete,
                            enabled: !actionsDisabled,
                            child: const _MyEventMenuRow(
                              icon: Icons.delete_outline_rounded,
                              label: 'Delete',
                            ),
                          ),
                        ];
                      },
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (event.genreName?.isNotEmpty ?? false)
                  Text(
                    event.genreName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                const SizedBox(height: 8),
                AppChip(
                  label: status,
                  selected: true,
                  onTap: null,
                  backgroundColor: statusColor.withValues(alpha: 0.14),
                  foregroundColor: statusColor,
                  borderColor: statusColor.withValues(alpha: 0.22),
                  selectedBackgroundColor: statusColor.withValues(alpha: 0.14),
                  selectedForegroundColor: statusColor,
                  selectedBorderColor: statusColor.withValues(alpha: 0.22),
                  compact: true,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        event.startDateTime.formatDateTime(
                          pattern: 'dd.MM.yyyy • HH:mm',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.payments_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        PriceFormatter.formatPriceWithBam(event.price),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MyEventCardImage extends StatelessWidget {
  const MyEventCardImage({
    super.key,
    required this.imageUrl,
  });

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = imageUrl?.trim();

    if (normalizedUrl != null && normalizedUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          normalizedUrl,
          width: 98,
          height: 98,
          fit: BoxFit.cover,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) return child;
            return _fallback(context, loading: true);
          },
          errorBuilder: (_, _, _) => _fallback(context),
        ),
      );
    }

    return _fallback(context);
  }

  Widget _fallback(BuildContext context, {bool loading = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 98,
      height: 98,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF3A3F52), const Color(0xFF1E2230)]
              : [const Color(0xFFD9E7FF), const Color(0xFFEEF3FB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: loading
          ? const Center(
              child: AppSpinner(size: 22, strokeWidth: 2),
            )
          : Icon(
              Icons.event_rounded,
              size: 34,
              color: theme.colorScheme.onSurfaceVariant,
            ),
    );
  }
}

class _MyEventMenuRow extends StatelessWidget {
  const _MyEventMenuRow({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: color == null ? null : TextStyle(color: color),
          ),
        ),
      ],
    );
  }
}