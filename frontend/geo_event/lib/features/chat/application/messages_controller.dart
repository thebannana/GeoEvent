import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/chat/data/chat_repository.dart';
import '../../../shared/chat/models/conversation_summary.dart';
import '../../../shared/chat/providers/chat_providers.dart';

class MessagesInboxState {
  final AsyncValue<List<ConversationSummary>> conversations;
  final String searchQuery;
  final bool unreadOnly;
  final int unreadCount;
  final bool initialized;
  final int page;
  final int pageSize;
  final int totalCount;
  final bool hasNextPage;
  final bool isLoadingMore;

  const MessagesInboxState({
    this.conversations = const AsyncValue.loading(),
    this.searchQuery = '',
    this.unreadOnly = false,
    this.unreadCount = 0,
    this.initialized = false,
    this.page = 1,
    this.pageSize = 20,
    this.totalCount = 0,
    this.hasNextPage = false,
    this.isLoadingMore = false,
  });

  MessagesInboxState copyWith({
    AsyncValue<List<ConversationSummary>>? conversations,
    String? searchQuery,
    bool? unreadOnly,
    int? unreadCount,
    bool? initialized,
    int? page,
    int? pageSize,
    int? totalCount,
    bool? hasNextPage,
    bool? isLoadingMore,
  }) {
    return MessagesInboxState(
      conversations: conversations ?? this.conversations,
      searchQuery: searchQuery ?? this.searchQuery,
      unreadOnly: unreadOnly ?? this.unreadOnly,
      unreadCount: unreadCount ?? this.unreadCount,
      initialized: initialized ?? this.initialized,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

final messagesInboxControllerProvider =
    NotifierProvider<MessagesInboxController, MessagesInboxState>(
  MessagesInboxController.new,
);

class MessagesInboxController extends Notifier<MessagesInboxState> {
  ChatRepository get _repo => ref.read(messagesRepositoryProvider);

  @override
  MessagesInboxState build() {
    Future.microtask(load);
    return const MessagesInboxState();
  }

  Future<void> load() async {
    final previous = state.conversations.valueOrNull;

    state = state.copyWith(
      conversations: previous == null
          ? const AsyncValue.loading()
          : AsyncData<List<ConversationSummary>>(previous),
      initialized: true,
      page: 1,
      totalCount: 0,
      hasNextPage: false,
      isLoadingMore: false,
    );

    final conversationsResult = await AsyncValue.guard(() async {
      return _repo.getThreads(
        page: 1,
        pageSize: state.pageSize,
        searchTerm: state.searchQuery.trim().isEmpty
            ? null
            : state.searchQuery.trim(),
        unreadOnly: state.unreadOnly,
      );
    });

    int unreadCount = state.unreadCount;
    try {
      unreadCount = await _repo.getUnreadCount();
    } catch (_) {}

    if (conversationsResult.hasError) {
      state = state.copyWith(
        conversations: AsyncValue.error(
          conversationsResult.error!,
          conversationsResult.stackTrace!,
        ),
        unreadCount: unreadCount,
      );
      return;
    }

    final paged = conversationsResult.requireValue;

    state = state.copyWith(
      conversations: AsyncData<List<ConversationSummary>>(
        List<ConversationSummary>.unmodifiable(paged.items),
      ),
      unreadCount: unreadCount,
      page: paged.page,
      pageSize: paged.pageSize,
      totalCount: paged.totalCount,
      hasNextPage: paged.hasNextPage,
      isLoadingMore: false,
    );
  }

  Future<void> refresh() => load();

  Future<void> loadNextPage() async {
    if (state.isLoadingMore || !state.hasNextPage) return;

    final current = state.conversations.valueOrNull ?? const <ConversationSummary>[];

    state = state.copyWith(isLoadingMore: true);

    try {
      final paged = await _repo.getThreads(
        page: state.page + 1,
        pageSize: state.pageSize,
        searchTerm: state.searchQuery.trim().isEmpty
            ? null
            : state.searchQuery.trim(),
        unreadOnly: state.unreadOnly,
      );

      final merged = <ConversationSummary>[
        ...current,
        ...paged.items.where(
          (item) => current.every((existing) => existing.threadId != item.threadId),
        ),
      ];

      state = state.copyWith(
        conversations: AsyncData<List<ConversationSummary>>(
          List<ConversationSummary>.unmodifiable(merged),
        ),
        page: paged.page,
        pageSize: paged.pageSize,
        totalCount: paged.totalCount,
        hasNextPage: paged.hasNextPage,
        isLoadingMore: false,
      );
    } catch (error, stackTrace) {
      state = state.copyWith(
        conversations: AsyncValue.error(error, stackTrace),
        isLoadingMore: false,
      );
    }
  }

  Future<void> setSearchQuery(String value) async {
    state = state.copyWith(searchQuery: value);
    await load();
  }

  Future<void> setUnreadOnly(bool value) async {
    state = state.copyWith(unreadOnly: value);
    await load();
  }

  void removeThreadLocally(int threadId) {
    final current = state.conversations.valueOrNull ?? const <ConversationSummary>[];

    int removedUnread = 0;
    final updated = current.where((c) {
      final keep = c.threadId != threadId;
      if (!keep) {
        removedUnread += c.unreadCount;
      }
      return keep;
    }).toList(growable: false);

    state = state.copyWith(
      conversations: AsyncData<List<ConversationSummary>>(updated),
      unreadCount: (state.unreadCount - removedUnread).clamp(0, 1 << 30),
      totalCount: state.totalCount > 0 ? state.totalCount - 1 : 0,
    );
  }

  void markThreadLocallyRead(int threadId) {
    final current = state.conversations.valueOrNull ?? const <ConversationSummary>[];

    var removedUnread = 0;
    final updated = current.map((conversation) {
      if (conversation.threadId != threadId) return conversation;
      removedUnread = conversation.unreadCount;
      return conversation.copyWith(unreadCount: 0);
    }).toList(growable: false);

    state = state.copyWith(
      conversations: AsyncData<List<ConversationSummary>>(updated),
      unreadCount: (state.unreadCount - removedUnread).clamp(0, 1 << 30),
    );
  }

  void updateConversationFromMessage({
    required int threadId,
    required String preview,
    required DateTime sentAt,
    required bool isMine,
  }) {
    final current = state.conversations.valueOrNull ?? const <ConversationSummary>[];

    final updated = current.map((conversation) {
      if (conversation.threadId != threadId) return conversation;

      return conversation.copyWith(
        lastMessageContent: preview,
        lastMessageSentAt: sentAt,
        isLastMessageFromMe: isMine,
      );
    }).toList(growable: false);

    updated.sort((a, b) => b.lastMessageSentAt.compareTo(a.lastMessageSentAt));

    state = state.copyWith(
      conversations: AsyncData<List<ConversationSummary>>(updated),
    );
  }
}