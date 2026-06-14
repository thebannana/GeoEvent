import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../../../../../core/config/app_config.dart';
import '../../../shared/chat/data/chat_repository.dart';
import '../../../shared/chat/models/chat_participant.dart';
import '../../../shared/chat/models/chat_thread_args.dart';
import '../../../shared/chat/models/chat_thread_details.dart';
import '../../../shared/chat/models/message_item.dart';
import '../../../shared/chat/providers/chat_providers.dart';
import '../../auth/application/auth_controller.dart';
import 'messages_controller.dart';


class ChatThreadState {
  final AsyncValue<ChatThreadDetails> details;
  final AsyncValue<List<MessageItem>> messages;
  final bool sending;
  final bool connectingRealtime;
  final bool realtimeConnected;
  final HubConnection? hubConnection;
  final MessageItem? replyingTo;

  const ChatThreadState({
    this.details = const AsyncValue.loading(),
    this.messages = const AsyncValue.loading(),
    this.sending = false,
    this.connectingRealtime = false,
    this.realtimeConnected = false,
    this.hubConnection,
    this.replyingTo,
  });

  ChatThreadState copyWith({
    AsyncValue<ChatThreadDetails>? details,
    AsyncValue<List<MessageItem>>? messages,
    bool? sending,
    bool? connectingRealtime,
    bool? realtimeConnected,
    HubConnection? hubConnection,
    bool clearHubConnection = false,
    MessageItem? replyingTo,
    bool clearReplyingTo = false,
  }) {
    return ChatThreadState(
      details: details ?? this.details,
      messages: messages ?? this.messages,
      sending: sending ?? this.sending,
      connectingRealtime: connectingRealtime ?? this.connectingRealtime,
      realtimeConnected: realtimeConnected ?? this.realtimeConnected,
      hubConnection: clearHubConnection ? null : hubConnection ?? this.hubConnection,
      replyingTo: clearReplyingTo ? null : replyingTo ?? this.replyingTo,
    );
  }
}

final chatThreadControllerProvider = StateNotifierProvider.autoDispose
    .family<ChatThreadController, ChatThreadState, ChatThreadArgs>((ref, args) {
  final controller = ChatThreadController(ref, args);
  ref.onDispose(controller.dispose);
  controller.load();
  return controller;
});

class ChatThreadController extends StateNotifier<ChatThreadState> {
  final Ref ref;
  final ChatThreadArgs args;

  ChatThreadController(this.ref, this.args) : super(const ChatThreadState());

  ChatRepository get repo => ref.read(messagesRepositoryProvider);

  Future<void> load() async {
    state = state.copyWith(
      details: const AsyncLoading(),
      messages: const AsyncLoading(),
    );

    final detailsResult = await AsyncValue.guard(() => repo.getThreadDetails(args.threadId));
    final messagesResult = await AsyncValue.guard(() async {
      final items = await repo.getThreadMessages(args.threadId);
      items.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      return items;
    });

    if (!mounted) return;

    state = state.copyWith(
      details: detailsResult,
      messages: messagesResult,
    );

    await markThreadRead();
    ref.read(messagesInboxControllerProvider.notifier).markThreadLocallyRead(args.threadId);
  }

  void setReplyingTo(MessageItem item) {
    if (!mounted) return;
    state = state.copyWith(replyingTo: item);
  }

  void clearReplyingTo() {
    if (!mounted) return;
    state = state.copyWith(clearReplyingTo: true);
  }

  Future<bool> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.sending) return false;

    state = state.copyWith(sending: true);

    try {
      final item = await repo.sendThreadMessage(
        threadId: args.threadId,
        content: trimmed,
        replyToMessageId: state.replyingTo?.id,
      );

      if (!mounted) return false;

      upsertMessage(item);
      state = state.copyWith(clearReplyingTo: true);
      return true;
    } finally {
      if (mounted) {
        state = state.copyWith(sending: false);
      }
    }
  }

  Future<void> editMessage({
    required int messageId,
    required String content,
  }) async {
    final item = await repo.editMessage(
      messageId: messageId,
      content: content,
    );

    if (!mounted) return;
    upsertMessage(item);
  }

  Future<void> deleteMessage(int messageId) async {
    final current = state.messages.valueOrNull ?? const <MessageItem>[];

    state = state.copyWith(
      messages: AsyncData(
        current.where((m) => m.id != messageId).toList(growable: false),
      ),
    );

    try {
      await repo.deleteMessage(messageId);
    } catch (_) {
      if (mounted) {
        state = state.copyWith(messages: AsyncData(current));
      }
      rethrow;
    }
  }

  Future<void> toggleLike(MessageItem item) async {
    final updated = item.isLikedByMe
        ? await repo.unlikeMessage(item.id)
        : await repo.likeMessage(item.id);

    if (!mounted) return;
    upsertMessage(updated);
  }

  Future<void> markThreadRead() async {
    await repo.markThreadRead(args.threadId);

    final current = state.messages.valueOrNull ?? const <MessageItem>[];
    final updated = current
        .map((m) => m.isRead ? m : m.copyWith(isRead: true))
        .toList(growable: false);

    if (!mounted) return;
    state = state.copyWith(messages: AsyncData(updated));
  }

  Future<void> connectRealtime() async {
    if (state.hubConnection != null || state.connectingRealtime || state.realtimeConnected) {
      return;
    }

    final token = ref.read(authStateProvider).accessToken;
    if (token == null || token.isEmpty) return;

    state = state.copyWith(connectingRealtime: true);

    final hub = HubConnectionBuilder()
        .withUrl(
          '${AppConfig.baseUrl}/hubs/chat',
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token,
          ),
        )
        .withAutomaticReconnect()
        .build();

    hub.on('MessageCreated', handleMessagePayload);
    hub.on('MessageUpdated', handleMessagePayload);
    hub.on('MessageLiked', handleMessagePayload);
    hub.on('MessageUnliked', handleMessagePayload);
    hub.on('MessageRead', handleMessagePayload);
    hub.on('MessageDeleted', handleDeletePayload);
    hub.on('PresenceChanged', handlePresencePayload);

    try {
      await hub.start();
      await hub.invoke('JoinThread', args: [args.threadId]);

      if (!mounted) {
        try {
          await hub.invoke('LeaveThread', args: [args.threadId]);
        } catch (_) {}
        try {
          await hub.stop();
        } catch (_) {}
        return;
      }

      state = state.copyWith(
        hubConnection: hub,
        connectingRealtime: false,
        realtimeConnected: true,
      );
    } catch (_) {
      try {
        await hub.stop();
      } catch (_) {}

      if (!mounted) return;

      state = state.copyWith(
        connectingRealtime: false,
        realtimeConnected: false,
        clearHubConnection: true,
      );
    }
  }

  void handleMessagePayload(List<Object?>? argsList) {
    if (!mounted || argsList == null || argsList.isEmpty) return;

    final raw = argsList.first;
    if (raw is! Map) return;

    try {
      final item = MessageItem.fromJson(Map<String, dynamic>.from(raw));
      if (item.threadId != args.threadId) return;
      upsertMessage(item);
    } catch (e, st) {
      debugPrint('SignalR payload parse error: $e');
      debugPrintStack(stackTrace: st);
      debugPrint('Raw payload: $raw');
    }
  }

  void handleDeletePayload(List<Object?>? argsList) {
    if (!mounted || argsList == null || argsList.isEmpty) return;

    final raw = argsList.first;
    if (raw is! Map) return;

    final threadId = (raw['threadId'] as num?)?.toInt();
    if (threadId != args.threadId) return;

    final messageId = (raw['messageId'] as num?)?.toInt();
    if (messageId == null) return;

    final current = state.messages.valueOrNull ?? const <MessageItem>[];
    state = state.copyWith(
      messages: AsyncData(
        current.where((m) => m.id != messageId).toList(growable: false),
      ),
    );
  }

  Future<void> leaveThread() async {
    await repo.leaveThread(args.threadId);
    ref.read(messagesInboxControllerProvider.notifier).removeThreadLocally(args.threadId);
  }

  void handlePresencePayload(List<Object?>? argsList) {
    if (!mounted || argsList == null || argsList.isEmpty) return;

    final raw = argsList.first;
    if (raw is! Map) return;

    final userId = (raw['userId'] as num?)?.toInt();
    final isOnline = raw['isOnline'] as bool? ?? false;
final lastActiveAt = raw['lastActiveAt'] != null
    ? DateTime.tryParse(raw['lastActiveAt'].toString())?.toLocal()
    : null;

    final current = state.details.valueOrNull;
    if (current == null || userId == null) return;

    final updatedParticipants = current.participants
        .map((p) {
          if (p.userId != userId) return p;
          return ChatParticipant(
            userId: p.userId,
            displayName: p.displayName,
            username: p.username,
            avatarUrl: p.avatarUrl,
            isOnline: isOnline,
            lastActiveAt: lastActiveAt,
            joinedAt: p.joinedAt,
          );
        })
        .toList(growable: false);

    state = state.copyWith(
      details: AsyncData(
        current.copyWith(
          participants: updatedParticipants,
          otherUserIsOnline:
              current.otherUserId == userId ? isOnline : current.otherUserIsOnline,
          otherUserLastActiveAt: current.otherUserId == userId
              ? lastActiveAt
              : current.otherUserLastActiveAt,
        ),
      ),
    );
  }

  void upsertMessage(MessageItem item) {
    if (!mounted) return;

    final current = List<MessageItem>.from(state.messages.valueOrNull ?? const <MessageItem>[]);
    final index = current.indexWhere((m) => m.id == item.id);

    if (index >= 0) {
      current[index] = item;
    } else {
      current.add(item);
    }

    current.sort((a, b) => a.sentAt.compareTo(b.sentAt));

    state = state.copyWith(messages: AsyncData(current));

    ref.read(messagesInboxControllerProvider.notifier).updateConversationFromMessage(
          threadId: item.threadId,
          preview: item.content,
          sentAt: item.sentAt,
          isMine: args.otherUserId == null ? false : item.senderId != args.otherUserId,
        );
  }

  @override
  void dispose() {
    final hub = state.hubConnection;
    if (hub != null) {
      Future.microtask(() async {
        try {
          await hub.invoke('LeaveThread', args: [args.threadId]);
        } catch (_) {}
        try {
          await hub.stop();
        } catch (_) {}
      });
    }
    super.dispose();
  }
}