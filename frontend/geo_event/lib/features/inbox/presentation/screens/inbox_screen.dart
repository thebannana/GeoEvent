import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/inbox_controller.dart';
import '../../../../shared/notifications/models/notification_item.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inboxControllerProvider);
    final ctrl = ref.read(inboxControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = state.displayed;
    final hasUnread =
        (state.notifications.valueOrNull ?? []).any((n) => !n.isRead);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: ctrl.load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                child: TextField(
                  controller: _searchController,
                  onChanged: ctrl.setSearch,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Search inbox',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: state.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ctrl.setSearch('');
                            },
                          )
                        : null,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                    isDense: true,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: state.filter == NotificationFilter.all,
                      onTap: () => ctrl.setFilter(NotificationFilter.all),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Oldest',
                      selected: state.sort == NotificationSort.oldest,
                      onTap: () {
                        ctrl.setSort(
                          state.sort == NotificationSort.oldest
                              ? NotificationSort.newest
                              : NotificationSort.oldest,
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Newest',
                      selected: state.sort == NotificationSort.newest,
                      onTap: () => ctrl.setSort(NotificationSort.newest),
                    ),
                    const Spacer(),
                    if (hasUnread)
                      TextButton(
                        onPressed: ctrl.markAllAsRead,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Mark all read',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (state.notifications.isLoading)
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(18, 16, 18, 24),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              )
            else if (state.notifications.hasError)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                sliver: SliverToBoxAdapter(
                  child: _ErrorState(onRetry: ctrl.load),
                ),
              )
            else if (items.isEmpty)
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(18, 8, 18, 24),
                sliver: SliverToBoxAdapter(
                  child: _EmptyState(),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                sliver: SliverList.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _NotificationCard(
                      item: item,
                      isDark: isDark,
                      onTap: () {
                        if (!item.isRead) {
                          ctrl.markAsRead(item.notificationId);
                        }
                      },
                      onDelete: () => ctrl.delete(item.notificationId),
                      onMarkRead: item.isRead
                          ? null
                          : () => ctrl.markAsRead(item.notificationId),
                    );
                  },
                ),
              ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem item;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onMarkRead;

  const _NotificationCard({
    required this.item,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
    this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    final meta = _NotificationMeta.from(item.type);
    final theme = Theme.of(context);
    final unreadBg = isDark
        ? const Color(0xFF1B2028)
        : theme.colorScheme.primary.withValues(alpha: 0.05);
    final readBg =
        isDark ? const Color(0xFF161A21) : const Color(0xFFF9FBFD);

    return Dismissible(
      key: ValueKey(item.notificationId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: Material(
        color: item.isRead ? readBg : unreadBg,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF2A303A)
                    : const Color(0xFFE3EAF3),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NotificationAvatar(meta: meta, isDark: isDark),
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
                              item.title,
                              style: TextStyle(
                                fontWeight: item.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                fontSize: 14,
                                height: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _MoreMenu(
                            onDelete: onDelete,
                            onMarkRead: onMarkRead,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.60)
                              : Colors.black.withValues(alpha: 0.55),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _TypeBadge(meta: meta),
                          const Spacer(),
                          Text(
                            _timeAgo(item.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.38)
                                  : Colors.black.withValues(alpha: 0.38),
                            ),
                          ),
                          if (!item.isRead) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationAvatar extends StatelessWidget {
  final _NotificationMeta meta;
  final bool isDark;

  const _NotificationAvatar({required this.meta, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: meta.color.withValues(alpha: isDark ? 0.22 : 0.15),
      ),
      child: Icon(meta.icon, size: 22, color: meta.color),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final _NotificationMeta meta;

  const _TypeBadge({required this.meta});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: meta.color.withValues(alpha: isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        meta.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: meta.color,
        ),
      ),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  final VoidCallback onDelete;
  final VoidCallback? onMarkRead;

  const _MoreMenu({required this.onDelete, this.onMarkRead});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) async {
        final result = await showMenu<String>(
          context: context,
          position: RelativeRect.fromLTRB(
            details.globalPosition.dx,
            details.globalPosition.dy,
            details.globalPosition.dx + 1,
            details.globalPosition.dy + 1,
          ),
          items: [
            if (onMarkRead != null)
              const PopupMenuItem(
                value: 'read',
                child: Row(
                  children: [
                    Icon(Icons.done_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Mark as read'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        );
        if (result == 'delete') onDelete();
        if (result == 'read') onMarkRead?.call();
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Icon(
          Icons.more_horiz_rounded,
          size: 18,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white38
              : Colors.black38,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? primary.withValues(alpha: isDark ? 0.22 : 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? primary.withValues(alpha: 0.6)
                : isDark
                    ? const Color(0xFF2A303A)
                    : const Color(0xFFE3EAF3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected
                ? primary
                : isDark
                    ? Colors.white70
                    : Colors.black54,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF17191D)
            : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2A303A)
              : const Color(0xFFE5EAF2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 30,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          const Text(
            'All caught up',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No notifications to show.',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF17191D)
            : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2A303A)
              : const Color(0xFFE5EAF2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 30,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          const Text(
            'Failed to load notifications',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pull to refresh or try again.',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _NotificationMeta {
  final IconData icon;
  final Color color;
  final String label;

  const _NotificationMeta({
    required this.icon,
    required this.color,
    required this.label,
  });

  factory _NotificationMeta.from(String type) {
    return switch (type) {
      'NewMessage' => _NotificationMeta(
          icon: Icons.chat_bubble_outline_rounded,
          color: const Color(0xFF5B9ED6),
          label: 'Message',
        ),
      'EventCreated' => _NotificationMeta(
          icon: Icons.event_available_rounded,
          color: const Color(0xFF6DBF82),
          label: 'Event',
        ),
      'EventUpdated' => _NotificationMeta(
          icon: Icons.edit_calendar_rounded,
          color: const Color(0xFFF0A500),
          label: 'Event',
        ),
      'EventCancelled' => _NotificationMeta(
          icon: Icons.event_busy_rounded,
          color: const Color(0xFFE05C5C),
          label: 'Event',
        ),
      'EventStartingSoon' => _NotificationMeta(
          icon: Icons.alarm_rounded,
          color: const Color(0xFFF0A500),
          label: 'Reminder',
        ),
      'ReservationConfirmed' => _NotificationMeta(
          icon: Icons.confirmation_num_outlined,
          color: const Color(0xFF6DBF82),
          label: 'Reservation',
        ),
      'ReservationExpired' => _NotificationMeta(
          icon: Icons.timer_off_outlined,
          color: const Color(0xFFE05C5C),
          label: 'Reservation',
        ),
      'TicketPurchased' => _NotificationMeta(
          icon: Icons.local_activity_rounded,
          color: const Color(0xFF6DBF82),
          label: 'Ticket',
        ),
      'TicketCancelled' => _NotificationMeta(
          icon: Icons.local_activity_outlined,
          color: const Color(0xFFE05C5C),
          label: 'Ticket',
        ),
      'PaymentSucceeded' => _NotificationMeta(
          icon: Icons.payments_outlined,
          color: const Color(0xFF6DBF82),
          label: 'Payment',
        ),
      'PaymentFailed' => _NotificationMeta(
          icon: Icons.money_off_rounded,
          color: const Color(0xFFE05C5C),
          label: 'Payment',
        ),
      'AccountBanned' => _NotificationMeta(
          icon: Icons.block_rounded,
          color: const Color(0xFFE05C5C),
          label: 'Account',
        ),
      'Welcome' => _NotificationMeta(
          icon: Icons.waving_hand_rounded,
          color: const Color(0xFF9B7BBF),
          label: 'Welcome',
        ),
      'EmailVerification' || 'PasswordReset' => _NotificationMeta(
          icon: Icons.security_rounded,
          color: const Color(0xFF5B9ED6),
          label: 'Security',
        ),
      _ => _NotificationMeta(
          icon: Icons.notifications_outlined,
          color: const Color(0xFF7A7A7A),
          label: 'General',
        ),
    };
  }
}

String _timeAgo(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime.toLocal());
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  final d = dateTime.toLocal();
  return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}