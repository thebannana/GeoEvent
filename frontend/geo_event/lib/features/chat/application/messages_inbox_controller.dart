import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/chat/data/chat_repository.dart';
import '../../../shared/chat/models/conversation_summary.dart';

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
    state = state.copyWith(conversations: const AsyncValue.loading());

    final conversationsResult =
        await AsyncValue.guard<List<ConversationSummary>>(
      _repo.getConversations,
    );

    int unreadCount = state.unreadCount;
    try {
      unreadCount = await _repo.getUnreadCount();
    } catch (_) {}

    state = state.copyWith(
      conversations: conversationsResult,
      unreadCount: unreadCount,
    );
  }

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value);
  }

  void setUnreadOnly(bool value) {
    state = state.copyWith(unreadOnly: value);
  }
}

final messagesInboxControllerProvider =
    NotifierProvider<MessagesInboxController, MessagesInboxState>(
  MessagesInboxController.new,
);