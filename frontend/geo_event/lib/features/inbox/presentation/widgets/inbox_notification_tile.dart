import 'package:flutter/material.dart';

import '../../../../shared/notifications/models/notification_item.dart';

class InboxNotificationTile extends StatelessWidget {
  final NotificationItem item;
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
    final type = item.type.toLowerCase();

    if (type.contains('message') || type.contains('chat')) {
      return const Color(0xFF5B8DEF);
    }
    if (type.contains('warning') || type.contains('alert')) {
      return const Color(0xFFFF8A65);
    }
    if (type.contains('event')) {
      return const Color(0xFF8E7CFF);
    }
    if (type.contains('invite')) {
      return const Color(0xFF4DB6AC);
    }
    return Theme.of(context).colorScheme.primary;
  }

  IconData _leadingIcon() {
    final type = item.type.toLowerCase();

    if (type.contains('message') || type.contains('chat')) {
      return Icons.chat_bubble_rounded;
    }
    if (type.contains('warning') || type.contains('alert')) {
      return Icons.notifications_active_rounded;
    }
    if (type.contains('event')) {
      return Icons.event_rounded;
    }
    if (type.contains('invite')) {
      return Icons.mail_rounded;
    }
    return Icons.notifications_rounded;
  }

  String _timeAgo() {
    final now = DateTime.now();
    final diff = now.difference(item.createdAt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = _accentColor(context);

    return Dismissible(
      key: ValueKey(item.notificationId),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete?.call();
        return false;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.25),
          ),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(
          Icons.delete_outline_rounded,
          color: theme.colorScheme.error,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B2028) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: item.isRead
                ? (isDark ? const Color(0xFF2A303A) : const Color(0xFFE3EAF3))
                : accent.withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _leadingIcon(),
                      color: accent,
                      size: 20,
                    ),
                  ),
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
                              _timeAgo(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.35,
                            color: theme.colorScheme.onSurfaceVariant,
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
                                    ? theme.colorScheme.onSurfaceVariant
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
                      color: theme.colorScheme.onSurfaceVariant,
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