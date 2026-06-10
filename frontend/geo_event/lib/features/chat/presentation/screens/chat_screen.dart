import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/chat/models/chat_thread_args.dart';
import '../../../../shared/chat/models/chat_thread_type.dart';
import '../../../../shared/chat/models/conversation_summary.dart';
import '../../application/messages_controller.dart';
import '../widgets/chat_avatar.dart';
import 'chat_thread_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messagesInboxControllerProvider);
    final controller = ref.read(messagesInboxControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = state.filteredConversations;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                child: TextField(
                  controller: _searchController,
                  onChanged: controller.setSearchQuery,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Search chats',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: state.searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              controller.setSearchQuery('');
                            },
                            icon: const Icon(Icons.close_rounded, size: 18),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
                    _TopFilterChip(
                      label: 'All',
                      selected: !state.unreadOnly,
                      onTap: () => controller.setUnreadOnly(false),
                    ),
                    const SizedBox(width: 8),
                    _TopFilterChip(
                      label: 'Unread',
                      selected: state.unreadOnly,
                      onTap: () => controller.setUnreadOnly(true),
                      trailingCount:
                          state.unreadCount > 0 ? state.unreadCount : null,
                    ),
                  ],
                ),
              ),
            ),
            if (state.conversations.isLoading)
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(18, 10, 18, 24),
                sliver: SliverToBoxAdapter(
                  child: _ChatLoadingState(),
                ),
              )
            else if (state.conversations.hasError)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                sliver: SliverToBoxAdapter(
                  child: _ChatErrorState(onRetry: controller.refresh),
                ),
              )
            else if (filtered.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                sliver: SliverToBoxAdapter(
                  child: _ChatEmptyState(
                    hasSearch: state.searchQuery.trim().isNotEmpty,
                    unreadOnly: state.unreadOnly,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                sliver: SliverList.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _ConversationCard(
                      item: item,
                      isDark: isDark,
                      onTap: () async {
                        controller.markThreadLocallyRead(item.threadId);

                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatThreadScreen(
                              args: ChatThreadArgs(
                                threadId: item.threadId,
                                type: item.type,
                                title: item.title,
                                otherUserId: item.otherUserId,
                                eventId: item.eventId,
                              ),
                            ),
                          ),
                        );

                        if (mounted) {
                          await controller.refresh();
                        }
                      },
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

class _ConversationCard extends StatelessWidget {
  final ConversationSummary item;
  final bool isDark;
  final VoidCallback onTap;

  const _ConversationCard({
    required this.item,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitlePrefix = item.isLastMessageFromMe ? 'You: ' : '';
    final resolvedTitle = _displayTitle(item);

    return Material(
      color: isDark ? const Color(0xFF17191D) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF2A303A)
                  : const Color(0xFFE5EAF2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChatAvatar(
                title: resolvedTitle,
                imageUrl: item.imageUrl,
                size: 46,
                type: item.type,
                showPresence: item.type == ChatThreadType.direct,
                isOnline: item.type == ChatThreadType.direct && item.isOnline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resolvedTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: item.unreadCount > 0
                              ? FontWeight.w700
                              : FontWeight.w600,
                          fontSize: 14,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$subtitlePrefix${item.lastMessageContent}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(item.lastMessageSentAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (item.unreadCount > 0)
                    Container(
                      constraints: const BoxConstraints(minWidth: 22),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.unreadCount.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _displayTitle(ConversationSummary item) {
    final value = item.title.trim();
    if (value.isNotEmpty) return value;

    if (item.type == ChatThreadType.direct && item.otherUserId != null) {
      return 'User ${item.otherUserId}';
    }

    return 'Chat';
  }

  static String _formatTime(DateTime value) {
    final now = DateTime.now();
    final local = value.toLocal();
    final diff = now.difference(local);

    if (diff.inDays >= 1) {
      return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}';
    }

    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _TopFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? trailingCount;

  const _TopFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailingCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(
                  alpha: isDark ? 0.22 : 0.12,
                )
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.6)
                : isDark
                    ? const Color(0xFF2A303A)
                    : const Color(0xFFE3EAF3),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected
                    ? theme.colorScheme.primary
                    : isDark
                        ? Colors.white70
                        : Colors.black54,
              ),
            ),
            if (trailingCount != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  trailingCount.toString(),
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChatLoadingState extends StatelessWidget {
  const _ChatLoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _ChatSkeletonCard(),
        SizedBox(height: 10),
        _ChatSkeletonCard(),
        SizedBox(height: 10),
        _ChatSkeletonCard(),
      ],
    );
  }
}

class _ChatSkeletonCard extends StatelessWidget {
  const _ChatSkeletonCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF17191D) : Colors.white;
    final line = isDark ? const Color(0xFF2A303A) : const Color(0xFFE5EAF2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: line),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: line,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 12,
                  decoration: BoxDecoration(
                    color: line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  height: 10,
                  decoration: BoxDecoration(
                    color: line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 160,
                  height: 10,
                  decoration: BoxDecoration(
                    color: line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: line,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatEmptyState extends StatelessWidget {
  final bool hasSearch;
  final bool unreadOnly;

  const _ChatEmptyState({
    required this.hasSearch,
    required this.unreadOnly,
  });

  @override
  Widget build(BuildContext context) {
    final title = hasSearch
        ? 'No matching chats'
        : unreadOnly
            ? 'No unread chats'
            : 'No chats yet';

    final subtitle = hasSearch
        ? 'Try a different search term.'
        : unreadOnly
            ? 'Unread conversations will appear here.'
            : 'Your conversations will appear here.';

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
            Icons.forum_outlined,
            size: 30,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
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

class _ChatErrorState extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _ChatErrorState({required this.onRetry});

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
            'Failed to load chats',
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