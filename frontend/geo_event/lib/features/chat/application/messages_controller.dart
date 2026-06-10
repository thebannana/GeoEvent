import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/chat/data/chat_repository.dart';
import '../../../shared/chat/models/conversation_summary.dart';
import '../../../shared/chat/providers/chat_providers.dart';

class MessagesInboxState {
  final AsyncValue<List<ConversationSummary>> conversations;
  final String searchQuery;
  final bool unreadOnly;
  final int unreadCount;

  const MessagesInboxState({
    this.conversations = const AsyncValue.loading(),
    this.searchQuery = '',
    this.unreadOnly = false,
    this.unreadCount = 0,
  });

  List<ConversationSummary> get filteredConversations {
    final items = conversations.valueOrNull ?? const <ConversationSummary>[];
    final query = searchQuery.trim().toLowerCase();

    return items.where((conversation) {
      final matchesUnread = !unreadOnly || conversation.unreadCount > 0;
      final matchesQuery = query.isEmpty ||
          conversation.title.toLowerCase().contains(query) ||
          conversation.lastMessageContent.toLowerCase().contains(query);

      return matchesUnread && matchesQuery;
    }).toList(growable: false);
  }

  MessagesInboxState copyWith({
    AsyncValue<List<ConversationSummary>>? conversations,
    String? searchQuery,
    bool? unreadOnly,
    int? unreadCount,
  }) {
    return MessagesInboxState(
      conversations: conversations ?? this.conversations,
      searchQuery: searchQuery ?? this.searchQuery,
      unreadOnly: unreadOnly ?? this.unreadOnly,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

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
    );

    final conversationsResult =
        await AsyncValue.guard<List<ConversationSummary>>(_repo.getThreads);

    int unreadCount = state.unreadCount;
    try {
      unreadCount = await _repo.getUnreadCount();
    } catch (_) {}

    state = state.copyWith(
      conversations: conversationsResult,
      unreadCount: unreadCount,
    );
  }

  Future<void> refresh() => load();

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value);
  }

  void setUnreadOnly(bool value) {
    state = state.copyWith(unreadOnly: value);
  }

void removeThreadLocally(int threadId) {
  final current = state.conversations.valueOrNull ?? const <ConversationSummary>[];

  int removedUnread = 0;
  final updated = current.where((c) {
    final keep = c.threadId != threadId;
    if (!keep) removedUnread = c.unreadCount;
    return keep;
  }).toList(growable: false);

  state = state.copyWith(
    conversations: AsyncData(updated),
    unreadCount: (state.unreadCount - removedUnread).clamp(0, 1 << 30),
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
      conversations: AsyncData(updated),
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

    state = state.copyWith(conversations: AsyncData(updated));
  }
}

final messagesInboxControllerProvider =
    NotifierProvider<MessagesInboxController, MessagesInboxState>(
  MessagesInboxController.new,
);