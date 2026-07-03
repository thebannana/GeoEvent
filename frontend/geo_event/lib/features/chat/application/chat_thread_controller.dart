import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geo_event/core/network/api_endpoints.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../../../shared/chat/data/chat_repository.dart';
import '../../../shared/chat/models/chat_participant.dart';
import '../../../shared/chat/models/chat_thread_args.dart';
import '../../../shared/chat/models/chat_thread_state.dart';
import '../../../shared/chat/models/message_item.dart';
import '../../../shared/chat/providers/chat_providers.dart';
import '../../auth/application/auth_controller.dart';
import 'messages_controller.dart';

final chatThreadControllerProvider = StateNotifierProvider.autoDispose
    .family<ChatThreadController, ChatThreadState, ChatThreadArgs>((ref, args) {
  final controller = ChatThreadController(ref, args);
  ref.onDispose(controller.dispose);
  Future.microtask(controller.load);
  return controller;
});

class ChatThreadController extends StateNotifier<ChatThreadState> {
  ChatThreadController(this.ref, this.args) : super(const ChatThreadState());

  final Ref ref;
  final ChatThreadArgs args;

  HubConnection? _hub;
  bool _loaded = false;
  bool _reloadingDetails = false;
  bool _reloadingMessages = false;

  ChatRepository get _repo => ref.read(messagesRepositoryProvider);

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;

    state = state.copyWith(
      details: const AsyncLoading(),
      messages: const AsyncLoading(),
    );

    final detailsResult =
        await AsyncValue.guard(() => _repo.getThreadDetails(args.threadId));

    final messagesResult = await AsyncValue.guard(() async {
      final items = await _repo.getThreadMessages(args.threadId);
      final sorted = [...items]..sort((a, b) => a.sentAt.compareTo(b.sentAt));
      return List<MessageItem>.unmodifiable(sorted);
    });

    if (!mounted) return;

    state = state.copyWith(
      details: detailsResult,
      messages: messagesResult,
    );

    try {
      await _markThreadRead();
    } catch (_) {}

    ref
        .read(messagesInboxControllerProvider.notifier)
        .markThreadLocallyRead(args.threadId);

    await _connectRealtime();
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
      final item = await _repo.sendThreadMessage(
        threadId: args.threadId,
        content: trimmed,
        replyToMessageId: state.replyingTo?.id,
      );

      if (!mounted) return false;

      _upsertMessage(item);
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
    final item = await _repo.editMessage(
      messageId: messageId,
      content: content,
    );

    if (!mounted) return;
    _upsertMessage(item);
  }

  Future<void> deleteMessage(int messageId) async {
    final current = state.messages.valueOrNull ?? const <MessageItem>[];

    state = state.copyWith(
      messages: AsyncData(
        List<MessageItem>.unmodifiable(
          current.where((m) => m.id != messageId),
        ),
      ),
    );

    try {
      await _repo.deleteMessage(messageId);
    } catch (_) {
      if (mounted) {
        state = state.copyWith(messages: AsyncData(current));
      }
      rethrow;
    }
  }

  Future<void> toggleLike(MessageItem item) async {
    final updated = item.isLikedByMe
        ? await _repo.unlikeMessage(item.id)
        : await _repo.likeMessage(item.id);

    if (!mounted) return;
    _upsertMessage(updated);
  }

  Future<void> leaveThread() async {
    await _repo.leaveThread(args.threadId);

    final hub = _hub;
    _hub = null;

    if (hub != null) {
      await _shutdownHub(hub, joined: true);
    }

    ref
        .read(messagesInboxControllerProvider.notifier)
        .removeThreadLocally(args.threadId);
  }

  Future<void> _markThreadRead() async {
    try {
      await _repo.markThreadRead(args.threadId);
    } catch (_) {
      return;
    }

    final current = state.messages.valueOrNull ?? const <MessageItem>[];
    final updated = current
        .map((m) => m.isRead ? m : m.copyWith(isRead: true))
        .toList(growable: false);

    if (!mounted) return;
    state = state.copyWith(
      messages: AsyncData(List<MessageItem>.unmodifiable(updated)),
    );
  }

  Future<void> _reloadDetails() async {
    if (_reloadingDetails) return;
    _reloadingDetails = true;

    try {
      final result =
          await AsyncValue.guard(() => _repo.getThreadDetails(args.threadId));

      if (!mounted) return;
      state = state.copyWith(details: result);
    } finally {
      _reloadingDetails = false;
    }
  }

  Future<void> _reloadMessages() async {
    if (_reloadingMessages) return;
    _reloadingMessages = true;

    try {
      final result = await AsyncValue.guard(() async {
        final items = await _repo.getThreadMessages(args.threadId);
        final sorted = [...items]..sort((a, b) => a.sentAt.compareTo(b.sentAt));
        return List<MessageItem>.unmodifiable(sorted);
      });

      if (!mounted) return;
      state = state.copyWith(messages: result);
    } finally {
      _reloadingMessages = false;
    }
  }

  Future<void> _connectRealtime() async {
    if (_hub != null ||
        state.connectingRealtime ||
        state.realtimeConnected) {
      return;
    }

    state = state.copyWith(connectingRealtime: true);

    final hub = HubConnectionBuilder()
        .withUrl(
          '${ApiEndpoints.chatBase}/hubs/chat',
          options: HttpConnectionOptions(
            accessTokenFactory: () async {
              return ref.read(authStateProvider).accessToken ?? '';
            },
          ),
        )
        .withAutomaticReconnect()
        .build();

    hub.on('MessageCreated', _handleMessagePayload);
    hub.on('MessageUpdated', _handleMessagePayload);
    hub.on('MessageLiked', _handleMessagePayload);
    hub.on('MessageUnliked', _handleMessagePayload);
    hub.on('MessageDeleted', _handleDeletePayload);
    hub.on('PresenceChanged', _handlePresencePayload);
    hub.on('ThreadRead', _handleThreadReadPayload);
    hub.on('ThreadUpdated', _handleThreadUpdatedPayload);
    hub.on('ParticipantLeft', _handleParticipantLeftPayload);

    try {
      await hub.start();
      await hub.invoke('JoinThread', args: [args.threadId]);

      if (!mounted) {
        await _shutdownHub(hub, joined: true);
        return;
      }

      _hub = hub;
      state = state.copyWith(
        connectingRealtime: false,
        realtimeConnected: true,
      );
    } catch (_) {
      await _shutdownHub(hub, joined: false);

      if (!mounted) return;

      state = state.copyWith(
        connectingRealtime: false,
        realtimeConnected: false,
      );
    }
  }

  void _handleMessagePayload(List<Object?>? argsList) {
    if (!mounted || argsList == null || argsList.isEmpty) return;

    final raw = argsList.first;
    if (raw is! Map) return;

    try {
      final item = MessageItem.fromJson(Map<String, dynamic>.from(raw));
      if (item.threadId != args.threadId) return;
      _upsertMessage(item);
    } catch (e, st) {
      debugPrint('SignalR payload parse error: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  void _handleDeletePayload(List<Object?>? argsList) {
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
        List<MessageItem>.unmodifiable(
          current.where((m) => m.id != messageId),
        ),
      ),
    );
  }

  void _handlePresencePayload(List<Object?>? argsList) {
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
          participants: List<ChatParticipant>.unmodifiable(updatedParticipants),
          otherUserIsOnline:
              current.otherUserId == userId ? isOnline : current.otherUserIsOnline,
          otherUserLastActiveAt:
              current.otherUserId == userId ? lastActiveAt : current.otherUserLastActiveAt,
        ),
      ),
    );
  }

  void _handleThreadReadPayload(List<Object?>? argsList) {
    if (!mounted || argsList == null || argsList.isEmpty) return;

    final raw = argsList.first;
    if (raw is! Map) return;

    final threadId = (raw['threadId'] as num?)?.toInt();
    if (threadId != args.threadId) return;

    Future.microtask(() async {
      await _reloadDetails();
      await ref.read(messagesInboxControllerProvider.notifier).refresh();
    });
  }

  void _handleThreadUpdatedPayload(List<Object?>? argsList) {
    if (!mounted || argsList == null || argsList.isEmpty) return;

    final raw = argsList.first;
    if (raw is! Map) return;

    final threadId = (raw['threadId'] as num?)?.toInt();
    if (threadId != args.threadId) return;

    Future.microtask(() async {
      await _reloadDetails();
      await ref.read(messagesInboxControllerProvider.notifier).refresh();
    });
  }

  void _handleParticipantLeftPayload(List<Object?>? argsList) {
    if (!mounted || argsList == null || argsList.isEmpty) return;

    final raw = argsList.first;
    if (raw is! Map) return;

    final threadId = (raw['threadId'] as num?)?.toInt();
    if (threadId != args.threadId) return;

    Future.microtask(() async {
      await _reloadDetails();
      await _reloadMessages();
      await ref.read(messagesInboxControllerProvider.notifier).refresh();
    });
  }

  void _upsertMessage(MessageItem item) {
    if (!mounted) return;

    final current =
        List<MessageItem>.from(state.messages.valueOrNull ?? const <MessageItem>[]);
    final index = current.indexWhere((m) => m.id == item.id);

    if (index >= 0) {
      current[index] = item;
    } else {
      current.add(item);
    }

    current.sort((a, b) => a.sentAt.compareTo(b.sentAt));

    state = state.copyWith(
      messages: AsyncData(List<MessageItem>.unmodifiable(current)),
    );

    final sessionUserId = ref.read(sessionUserIdProvider);
    ref.read(messagesInboxControllerProvider.notifier).updateConversationFromMessage(
          threadId: item.threadId,
          preview: item.content,
          sentAt: item.sentAt,
          isMine: sessionUserId != null && item.senderId == sessionUserId,
        );
  }

  Future<void> _shutdownHub(HubConnection hub, {required bool joined}) async {
    if (joined) {
      try {
        await hub.invoke('LeaveThread', args: [args.threadId]);
      } catch (_) {}
    }

    try {
      await hub.stop();
    } catch (_) {}
  }

  @override
  void dispose() {
    final hub = _hub;
    if (hub != null) {
      Future.microtask(() => _shutdownHub(hub, joined: true));
    }
    super.dispose();
  }
}