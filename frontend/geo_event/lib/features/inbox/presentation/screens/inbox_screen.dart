import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/feedback/app_empty_state.dart';
import '../../../../core/widgets/feedback/app_error_state.dart';
import '../../../../core/widgets/feedback/app_loading_indicator.dart';
import '../../../../core/widgets/feedback/app_spinner.dart';
import '../../../../core/widgets/inputs/app_chip.dart';
import '../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../shared/notifications/models/inbox_state.dart';
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
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(inboxControllerProvider.notifier).loadNotifications();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inboxControllerProvider);
    final ctrl = ref.read(inboxControllerProvider.notifier);

    final allItems = state.notifications;
    final items = state.displayed;
    final hasUnread = allItems.any((n) => n.isUnread);
    final usingServerPagingView = state.isUsingServerPagingView;

    return AppScaffold(
      child: RefreshIndicator(
        onRefresh: ctrl.refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                child: Text(
                  'Inbox',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),
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
                      label: 'Unread',
                      selected: state.filter == NotificationFilter.unread,
                      onTap: () => ctrl.setFilter(NotificationFilter.unread),
                    ),
                    const SizedBox(width: 8),
                    AppChip(
                      label: 'Oldest',
                      selected: state.sort == NotificationSort.oldest,
                      onTap: () => ctrl.setSort(NotificationSort.oldest),
                    ),
                    const SizedBox(width: 8),
                    AppChip(
                      label: 'Newest',
                      selected: state.sort == NotificationSort.newest,
                      onTap: () => ctrl.setSort(NotificationSort.newest),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (usingServerPagingView && state.totalCount > 0)
                      Text(
                        '${allItems.length} of ${state.totalCount} notifications',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (hasUnread)
                          TextButton(
                            onPressed: ctrl.markAllAsRead,
                            child: const Text('Mark all read'),
                          ),
                        if (allItems.isNotEmpty)
                          TextButton(
                            onPressed: ctrl.deleteAll,
                            child: const Text('Delete all'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (state.isLoading)
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
            else if (state.hasError && allItems.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                sliver: SliverToBoxAdapter(
                  child: AppErrorState(
                    title: 'Failed to load notifications',
                    message:
                        state.errorMessage ?? 'Pull to refresh or try again.',
                    onRetry: ctrl.loadNotifications,
                  ),
                ),
              )
            else if (items.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                sliver: SliverToBoxAdapter(
                  child: AppEmptyState(
                    icon: Icons.notifications_none_rounded,
                    title: allItems.isEmpty ? 'All caught up' : 'No matches found',
                    message: allItems.isEmpty
                        ? 'No notifications to show.'
                        : 'Try a different search or filter.',
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                sliver: SliverList.separated(
                  itemCount: items.length + (state.isLoadingMore ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index >= items.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: AppSpinner(size: 22, strokeWidth: 2),
                        ),
                      );
                    }

                    final item = items[index];

                    if (usingServerPagingView &&
                        state.hasMore &&
                        !state.isLoadingMore &&
                        index >= items.length - 3) {
                      Future.microtask(ctrl.loadMore);
                    }

                    return InboxNotificationTile(
                      item: item,
                      onTap: () {
                        if (!item.isRead) {
                          ctrl.markAsRead(item.id);
                        }
                      },
                      onDelete: () => ctrl.deleteNotification(item.id),
                      onMarkAsRead:
                          item.isRead ? null : () => ctrl.markAsRead(item.id),
                    );
                  },
                ),
              ),
            if (!state.isLoading &&
                usingServerPagingView &&
                state.hasMore &&
                !state.isLoadingMore)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  child: Center(
                    child: OutlinedButton(
                      onPressed: ctrl.loadMore,
                      child: const Text('Load more'),
                    ),
                  ),
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