import 'package:flutter/material.dart';

import '../../../../core/utils/date_time_extensions.dart';
import '../../../../shared/notifications/models/notification_model.dart';

class InboxNotificationTile extends StatelessWidget {
  final NotificationModel item;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onDelete;

  const InboxNotificationTile({
    super.key,
    required this.item,
    this.onTap,
    this.onMarkAsRead,
    this.onDelete,
  });

  Color _accentColor(BuildContext context) {
    switch (item.type) {
      case NotificationType.message:
        return const Color(0xFF5B8DEF);
      case NotificationType.eventInvite:
        return const Color(0xFF4DB6AC);
      case NotificationType.eventUpdate:
      case NotificationType.eventCancelled:
        return const Color(0xFF8E7CFF);
      case NotificationType.ticketConfirmed:
        return const Color(0xFF66BB6A);
      case NotificationType.ticketCancelled:
        return const Color(0xFFFF8A65);
      case NotificationType.newFollower:
        return const Color(0xFFE57373);
      case NotificationType.system:
      case NotificationType.unknown:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _leadingIcon() {
    switch (item.type) {
      case NotificationType.message:
        return Icons.chat_bubble_rounded;
      case NotificationType.eventInvite:
        return Icons.mail_rounded;
      case NotificationType.eventUpdate:
      case NotificationType.eventCancelled:
        return Icons.event_rounded;
      case NotificationType.ticketConfirmed:
        return Icons.confirmation_number_rounded;
      case NotificationType.ticketCancelled:
        return Icons.event_busy_rounded;
      case NotificationType.newFollower:
        return Icons.person_add_alt_1_rounded;
      case NotificationType.system:
      case NotificationType.unknown:
        return Icons.notifications_rounded;
    }
  }

  Widget _leadingVisual(BuildContext context, Color accent) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Icon(
        _leadingIcon(),
        color: accent,
        size: 20,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = _accentColor(context);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete?.call();
        return false;
      },
      background: Container(
        decoration: BoxDecoration(
          color: colorScheme.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.error.withValues(alpha: 0.25),
          ),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(
          Icons.delete_outline_rounded,
          color: colorScheme.error,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: item.isRead
                    ? colorScheme.outline.withValues(alpha: 0.45)
                    : accent.withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _leadingVisual(context, accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: item.isRead
                                      ? FontWeight.w700
                                      : FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item.createdAt.timeAgo(short: true),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.35,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (!item.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            if (!item.isRead) const SizedBox(width: 8),
                            Text(
                              item.isRead ? 'Read' : 'Unread',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: item.isRead
                                    ? colorScheme.onSurfaceVariant
                                    : accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_horiz_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'read':
                          onMarkAsRead?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (!item.isRead)
                        const PopupMenuItem<String>(
                          value: 'read',
                          child: Text('Mark as read'),
                        ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}