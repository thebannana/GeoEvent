import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../../../core/config/app_config.dart';
import '../../auth/application/auth_controller.dart';
import '../../../shared/chat/data/chat_repository.dart';
import '../../../shared/chat/models/message_item.dart';

class ChatThreadArgs {
  final int otherUserId;
  final int? eventId;
  final String title;

  const ChatThreadArgs({
    required this.otherUserId,
    required this.title,
    this.eventId,
  });
}

class ChatThreadState {
  final AsyncValue<List<MessageItem>> thread;
  final bool sending;
  final HubConnection? hubConnection;

  const ChatThreadState({
    required this.thread,
    this.sending = false,
    this.hubConnection,
  });

  ChatThreadState copyWith({
    AsyncValue<List<MessageItem>>? thread,
    bool? sending,
    HubConnection? hubConnection,
  }) {
    return ChatThreadState(
      thread: thread ?? this.thread,
      sending: sending ?? this.sending,
      hubConnection: hubConnection ?? this.hubConnection,
    );
  }
}

final chatThreadControllerProvider = StateNotifierProvider.family<
    ChatThreadController, ChatThreadState, ChatThreadArgs>((ref, args) {
  return ChatThreadController(ref, args)..load();
});

class ChatThreadController extends StateNotifier<ChatThreadState> {
  final Ref ref;
  final ChatThreadArgs args;

  ChatThreadController(this.ref, this.args)
      : super(const ChatThreadState(thread: AsyncLoading()));

  ChatRepository get _repo => ref.read(messagesRepositoryProvider);

  Future<void> load() async {
    state = state.copyWith(thread: const AsyncLoading());
    final result = await AsyncValue.guard<List<MessageItem>>(() async {
      return _repo.getConversation(
        otherUserId: args.otherUserId,
        eventId: args.eventId,
      );
    });

    state = state.copyWith(thread: result);
  }

  Future<bool> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    state = state.copyWith(sending: true);
    try {
      final item = await _repo.sendMessage(
        recipientId: args.otherUserId,
        content: trimmed,
        eventId: args.eventId,
      );
      _upsert(item);
      return true;
    } finally {
      state = state.copyWith(sending: false);
    }
  }

  Future<void> editMessage({
    required int messageId,
    required String content,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    final item = await _repo.editMessage(
      messageId: messageId,
      content: trimmed,
    );
    _upsert(item);
  }

  Future<void> deleteMessage(int messageId) async {
    await _repo.deleteMessage(messageId);
    final current = state.thread.valueOrNull ?? <MessageItem>[];
    state = state.copyWith(
      thread: AsyncData(current.where((m) => m.id != messageId).toList()),
    );
  }

  Future<void> likeMessage(int messageId) async {
    final item = await _repo.likeMessage(messageId);
    _upsert(item);
  }

  Future<void> unlikeMessage(int messageId) async {
    final item = await _repo.unlikeMessage(messageId);
    _upsert(item);
  }

  Future<void> markMessageRead(int messageId) async {
    final item = await _repo.markMessageAsRead(messageId);
    _upsert(item);
  }

  Future<void> markConversationRead() async {
    await _repo.markConversationAsRead(otherUserId: args.otherUserId);
    final current = state.thread.valueOrNull ?? <MessageItem>[];
    final myUserId = ref.read(authStateProvider).user?.userId;

    if (myUserId == null) return;

    final updated = current.map((m) {
      if (m.senderId == args.otherUserId &&
          m.recipientId == myUserId &&
          !m.isRead) {
        return m.copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
      }
      return m;
    }).toList();

    state = state.copyWith(thread: AsyncData(updated));
  }

  Future<void> connectRealtime() async {
    if (state.hubConnection != null) return;

    final authState = ref.read(authStateProvider);
    final token = authState.accessToken;
    if (token == null || token.isEmpty) return;

    final hubUrl = '${AppConfig.baseUrl}/hubs/messages';

    final hub = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token,
          ),
        )
        .withAutomaticReconnect()
        .build();

    hub.on('MessageCreated', _handleMessagePayload);
    hub.on('MessageUpdated', _handleMessagePayload);
    hub.on('MessageLiked', _handleMessagePayload);
    hub.on('MessageUnliked', _handleMessagePayload);
    hub.on('MessageRead', _handleMessagePayload);
    hub.on('MessageDeleted', _handleDeletePayload);

    try {
      await hub.start();
      state = state.copyWith(hubConnection: hub);
    } catch (_) {
      await hub.stop();
    }
  }

  Future<void> disposeRealtime() async {
    final hub = state.hubConnection;
    if (hub != null) {
      await hub.stop();
    }
    state = state.copyWith(hubConnection: null);
  }

  void _handleMessagePayload(List<Object?>? argsList) {
    if (argsList == null || argsList.isEmpty) return;
    final raw = argsList.first;
    if (raw is Map) {
      final item = MessageItem.fromJson(Map<String, dynamic>.from(raw));
      final isConversationMatch =
          (item.senderId == args.otherUserId ||
              item.recipientId == args.otherUserId) &&
          (args.eventId == null || item.eventId == args.eventId);

      if (isConversationMatch) {
        _upsert(item);
      }
    }
  }

  void _handleDeletePayload(List<Object?>? argsList) {
    if (argsList == null || argsList.isEmpty) return;
    final raw = argsList.first;
    if (raw is Map) {
      final dynamic messageIdRaw = raw['messageId'];
      final int? messageId =
          messageIdRaw is int ? messageIdRaw : int.tryParse('$messageIdRaw');

      if (messageId != null) {
        final current = state.thread.valueOrNull ?? <MessageItem>[];
        state = state.copyWith(
          thread: AsyncData(
            current.where((m) => m.id != messageId).toList(),
          ),
        );
      }
    }
  }

  void _upsert(MessageItem item) {
    final current = List<MessageItem>.from(
      state.thread.valueOrNull ?? <MessageItem>[],
    );
    final index = current.indexWhere((m) => m.id == item.id);

    if (index >= 0) {
      current[index] = item;
    } else {
      current.add(item);
    }

    current.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    state = state.copyWith(thread: AsyncData(current));
  }
}