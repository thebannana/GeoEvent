import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/debounce.dart';
import '../../../../core/utils/date_time_extensions.dart';
import '../../../../core/widgets/feedback/app_empty_state.dart';
import '../../../../core/widgets/feedback/app_error_state.dart';
import '../../../../core/widgets/feedback/app_spinner.dart';
import '../../../../core/widgets/inputs/app_chip.dart';
import '../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../core/widgets/surfaces/app_surface_card.dart';
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
  final _scrollController = ScrollController();
  final _searchDebouncer = Debouncer(delay: const Duration(milliseconds: 350));

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(messagesInboxControllerProvider.notifier).loadInitial();
});
  }

  void _onSearchChanged(String value) {
    _searchDebouncer.run(() {
      ref.read(messagesInboxControllerProvider.notifier).setSearchQuery(value);
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      ref.read(messagesInboxControllerProvider.notifier).loadNextPage();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _searchDebouncer.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messagesInboxControllerProvider);
    final controller = ref.read(messagesInboxControllerProvider.notifier);
    final conversations =
        state.conversations.valueOrNull ?? const <ConversationSummary>[];
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final isInitialLoading =
        state.conversations.isLoading && conversations.isEmpty;
    final isInitialError =
        state.conversations.hasError && conversations.isEmpty;
    final isEmpty = conversations.isEmpty && !isInitialLoading && !isInitialError;

    return AppScaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      child: SafeArea(
        top: false,
        bottom: false,
        maintainBottomViewPadding: true,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: bottomInset),
          child: RefreshIndicator(
            onRefresh: controller.refresh,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      textInputAction: TextInputAction.search,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Search chats',
                        helperText: state.searchQuery.isNotEmpty
                            ? 'Showing filtered chat results.'
                            : 'Search by chat title or content.',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: state.searchQuery.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchDebouncer.cancel();
                                  _searchController.clear();
                                  controller.setSearchQuery('');
                                },
                                tooltip: 'Clear search',
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                ),
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
                if (isInitialLoading)
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(18, 10, 18, 24),
                    sliver: SliverToBoxAdapter(
                      child: _ChatLoadingState(),
                    ),
                  )
                else if (isInitialError)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                    sliver: SliverToBoxAdapter(
                      child: _ChatErrorState(onRetry: controller.refresh),
                    ),
                  )
                else if (isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                    sliver: SliverFillRemaining(
                      hasScrollBody: false,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: _ChatEmptyState(
                          hasSearch: state.searchQuery.trim().isNotEmpty,
                          unreadOnly: state.unreadOnly,
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                    sliver: SliverList.separated(
                      itemCount:
                          conversations.length + (state.isLoadingMore ? 1 : 0),
                      separatorBuilder: (_, index) {
                        if (index >= conversations.length - 1) {
                          return const SizedBox.shrink();
                        }
                        return const SizedBox(height: 10);
                      },
                      itemBuilder: (context, index) {
                        if (index >= conversations.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: AppSpinner(size: 22, strokeWidth: 2.4),
                            ),
                          );
                        }

                        final item = conversations[index];

                        return KeyedSubtree(
                          key: ValueKey(item.threadId),
                          child: _ConversationCard(
                            item: item,
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
                          ),
                        );
                      },
                    ),
                  ),
                SliverToBoxAdapter(
                  child: SizedBox(height: 20 + bottomInset),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  final ConversationSummary item;
  final VoidCallback onTap;

  const _ConversationCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitlePrefix = item.isLastMessageFromMe ? 'You: ' : '';
    final resolvedTitle = _displayTitle(item);
    final preview = _previewText(item);

    return AppSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                    '$subtitlePrefix$preview',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      height: 1.35,
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
                item.lastMessageSentAt.isToday
                    ? item.lastMessageSentAt.formatTime()
                    : item.lastMessageSentAt.formatDate(pattern: 'dd.MM'),
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
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
    );
  }

  static String _displayTitle(ConversationSummary item) {
    final title = item.title.trim();
    if (title.isNotEmpty && title.toLowerCase() != 'direct chat') {
      return title;
    }

    final displayName = item.otherUserDisplayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final username = cleanUsername(item.otherUserUsername);
    if (username != null) {
      return username;
    }

    if (item.type == ChatThreadType.direct) {
      return 'Direct chat';
    }

    return 'Chat';
  }

  static String _previewText(ConversationSummary item) {
    final raw = item.lastMessageContent.trim();
    if (raw.isNotEmpty) return raw;

    if (item.type == ChatThreadType.direct) {
      return 'No messages yet';
    }

    return 'No messages in this chat yet';
  }

  static String? cleanUsername(String? value) {
    final cleaned = value?.trim().replaceFirst(RegExp(r'^@+'), '');
    if (cleaned == null || cleaned.isEmpty) return null;
    return '@$cleaned';
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
    return AppChip(
      label: trailingCount != null ? '$label ($trailingCount)' : label,
      selected: selected,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      icon: null,
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
    final theme = Theme.of(context);
    final line = theme.dividerColor;

    return AppSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

    return AppEmptyState(
      title: title,
      message: subtitle,
      icon: Icons.forum_outlined,
      padding: const EdgeInsets.all(18),
    );
  }
}

class _ChatErrorState extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _ChatErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return AppErrorState(
      title: 'Failed to load chats',
      message: 'Pull to refresh or try again.',
      onRetry: onRetry,
    );
  }
}