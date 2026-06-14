import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/glass_scaffold.dart';
import '../../application/inbox_controller.dart';
import '../widgets/inbox_notification_tile.dart';

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
    final items = state.displayed;
    final hasUnread =
        (state.notifications.valueOrNull ?? []).any((n) => !n.isRead);

    return GlassScaffold(
      child: RefreshIndicator(
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
                    AppChip(
                      label: 'All',
                      selected: state.filter == NotificationFilter.all,
                      onTap: () => ctrl.setFilter(NotificationFilter.all),
                    ),
                    const SizedBox(width: 8),
                    AppChip(
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
                    AppChip(
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
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                  child: AppLoadingIndicator(
                    title: 'Loading inbox',
                    message: 'Fetching your latest notifications...',
                    centered: false,
                  ),
                ),
              )
            else if (state.notifications.hasError)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                sliver: SliverToBoxAdapter(
                  child: AppErrorState(
                    title: 'Failed to load notifications',
                    message: 'Pull to refresh or try again.',
                    onRetry: ctrl.load,
                  ),
                ),
              )
            else if (items.isEmpty)
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(18, 8, 18, 24),
                sliver: SliverToBoxAdapter(
                  child: AppEmptyState(
                    icon: Icons.notifications_none_rounded,
                    title: 'All caught up',
                    message: 'No notifications to show.',
                  ),
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
                    return InboxNotificationTile(
                      item: item,
                      onTap: () {
                        if (!item.isRead) {
                          ctrl.markAsRead(item.notificationId);
                        }
                      },
                      onDelete: () => ctrl.delete(item.notificationId),
                      onMarkAsRead: item.isRead
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