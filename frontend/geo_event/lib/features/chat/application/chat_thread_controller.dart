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
      messagesPage: 1,
      messagesTotalCount: 0,
      hasMoreMessages: false,
      loadingOlderMessages: false,
    );

    final detailsResult =
        await AsyncValue.guard(() => _repo.getThreadDetails(args.threadId));

    final messagesResult = await AsyncValue.guard(() async {
      final paged = await _repo.getThreadMessages(
        threadId: args.threadId,
        page: 1,
        pageSize: state.messagesPageSize,
      );

      final sorted = [...paged.items]
        ..sort((a, b) => a.sentAt.compareTo(b.sentAt));

      state = state.copyWith(
        messagesPage: paged.page,
        messagesPageSize: paged.pageSize,
        messagesTotalCount: paged.totalCount,
        hasMoreMessages: paged.hasNextPage,
      );

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

  Future<void> loadOlderMessages() async {
    if (state.loadingOlderMessages || !state.hasMoreMessages) return;

    final current = state.messages.valueOrNull ?? const <MessageItem>[];

    state = state.copyWith(loadingOlderMessages: true);

    try {
      final paged = await _repo.getThreadMessages(
        threadId: args.threadId,
        page: state.messagesPage + 1,
        pageSize: state.messagesPageSize,
      );

      final merged = <MessageItem>[
        ...paged.items,
        ...current,
      ]..sort((a, b) => a.sentAt.compareTo(b.sentAt));

      state = state.copyWith(
        messages: AsyncData(List<MessageItem>.unmodifiable(merged)),
        messagesPage: paged.page,
        messagesPageSize: paged.pageSize,
        messagesTotalCount: paged.totalCount,
        hasMoreMessages: paged.hasNextPage,
        loadingOlderMessages: false,
      );
    } catch (error, stackTrace) {
      if (!mounted) return;

      state = state.copyWith(
        messages: AsyncError(error, stackTrace),
        loadingOlderMessages: false,
      );
    }
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
    if (trimmed.isEmpty) return false;

    final sessionUserId = ref.read(sessionUserIdProvider);
    final replyingTo = state.replyingTo;
    final now = DateTime.now().toUtc();
    final tempId = -now.microsecondsSinceEpoch;
    final clientTag = 'temp_$tempId';

    final optimistic = MessageItem(
      id: tempId,
      threadId: args.threadId,
      senderId: sessionUserId ?? 0,
      content: trimmed,
      isRead: true,
      likesCount: 0,
      isLikedByMe: false,
      sentAt: now,
      readAt: null,
      editedAt: null,
      senderDisplayName: 'You',
      senderAvatarUrl: null,
      replyToMessageId: replyingTo?.id,
      replyPreview: replyingTo?.content,
      replySenderName: replyingTo?.senderDisplayName,
      isPending: true,
      isFailed: false,
      clientTag: clientTag,
    );

    _upsertMessage(optimistic);

    state = state.copyWith(
      sending: true,
      clearReplyingTo: true,
    );

    try {
      final item = await _repo.sendThreadMessage(
        threadId: args.threadId,
        content: trimmed,
        replyToMessageId: replyingTo?.id,
      );

      if (!mounted) return false;

      _replaceOptimisticMessage(
        tempId: tempId,
        clientTag: clientTag,
        serverItem: item.copyWith(
          isPending: false,
          isFailed: false,
          clientTag: item.clientTag ?? clientTag,
        ),
      );

      return true;
    } catch (_) {
      if (!mounted) return false;
      _markMessageFailed(tempId);
      return false;
    } finally {
      if (mounted) {
        state = state.copyWith(sending: false);
      }
    }
  }

  Future<void> resendMessage(MessageItem failedItem) async {
    if (!failedItem.isFailed || failedItem.isPending) return;

    final current = List<MessageItem>.from(
      state.messages.valueOrNull ?? const <MessageItem>[],
    );
    final index = current.indexWhere((m) => m.id == failedItem.id);
    if (index < 0) return;

    final retryClientTag =
        failedItem.clientTag?.trim().isNotEmpty == true
            ? '${failedItem.clientTag}_retry_${DateTime.now().toUtc().microsecondsSinceEpoch}'
            : 'retry_${DateTime.now().toUtc().microsecondsSinceEpoch}_${failedItem.id}';

    current[index] = current[index].copyWith(
      isPending: true,
      isFailed: false,
      clientTag: retryClientTag,
    );

    state = state.copyWith(
      messages: AsyncData(List<MessageItem>.unmodifiable(current)),
    );

    try {
      final sent = await _repo.sendThreadMessage(
        threadId: failedItem.threadId,
        content: failedItem.content,
        replyToMessageId: failedItem.replyToMessageId,
      );

      if (!mounted) return;

      _replaceOptimisticMessage(
        tempId: failedItem.id,
        clientTag: retryClientTag,
        serverItem: sent.copyWith(
          isPending: false,
          isFailed: false,
          clientTag: sent.clientTag ?? retryClientTag,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _markMessageFailed(failedItem.id);
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
    _upsertMessage(item.copyWith(isPending: false, isFailed: false));
  }

  Future<void> deleteMessage(int messageId) async {
    final current = List<MessageItem>.from(
      state.messages.valueOrNull ?? const <MessageItem>[],
    );
    final removedIndex = current.indexWhere((m) => m.id == messageId);
    if (removedIndex < 0) return;

    final removedItem = current[removedIndex];
    current.removeAt(removedIndex);

    state = state.copyWith(
      messages: AsyncData(List<MessageItem>.unmodifiable(current)),
    );

    try {
      await _repo.deleteMessage(messageId);
    } catch (_) {
      if (mounted) {
        final latest = List<MessageItem>.from(
          state.messages.valueOrNull ?? const <MessageItem>[],
        );
        final alreadyExists = latest.any((m) => m.id == removedItem.id);
        if (!alreadyExists) {
          latest.insert(
            removedIndex.clamp(0, latest.length),
            removedItem,
          );
          latest.sort((a, b) => a.sentAt.compareTo(b.sentAt));
          state = state.copyWith(
            messages: AsyncData(List<MessageItem>.unmodifiable(latest)),
          );
        }
      }
      rethrow;
    }
  }

  Future<void> toggleLike(MessageItem item) async {
    final optimistic = item.copyWith(
      isLikedByMe: !item.isLikedByMe,
      likesCount: item.isLikedByMe
          ? (item.likesCount > 0 ? item.likesCount - 1 : 0)
          : item.likesCount + 1,
    );

    _upsertMessage(optimistic);

    try {
      final updated = item.isLikedByMe
          ? await _repo.unlikeMessage(item.id)
          : await _repo.likeMessage(item.id);

      if (!mounted) return;
      _upsertMessage(
        updated.copyWith(
          clientTag: item.clientTag,
          isPending: false,
          isFailed: false,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _upsertMessage(item);
    }
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

    await ref.read(messagesInboxControllerProvider.notifier).refresh();
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
        final paged = await _repo.getThreadMessages(
          threadId: args.threadId,
          page: 1,
          pageSize: state.messagesPageSize,
        );

        final existing = state.messages.valueOrNull ?? const <MessageItem>[];
        final pendingOrFailed = existing.where((m) => m.isPending || m.isFailed);

        final merged = <MessageItem>[
          ...paged.items,
          ...pendingOrFailed.where(
            (local) => !_containsEquivalentServerMessage(paged.items, local),
          ),
        ]..sort((a, b) => a.sentAt.compareTo(b.sentAt));

        state = state.copyWith(
          messagesPage: paged.page,
          messagesPageSize: paged.pageSize,
          messagesTotalCount: paged.totalCount,
          hasMoreMessages: paged.hasNextPage,
          loadingOlderMessages: false,
        );

        return List<MessageItem>.unmodifiable(merged);
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
          ApiEndpoints.chatHub,
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

      _upsertMessage(item.copyWith(isPending: false, isFailed: false));
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

    _removeMessage(messageId);
  }

  void _handlePresencePayload(List<Object?>? argsList) {
    if (!mounted || argsList == null || argsList.isEmpty) return;

    final raw = argsList.first;
    if (raw is! Map) return;

    final userId = (raw['userId'] as num?)?.toInt();
    final isOnline = raw['isOnline'] as bool? ?? false;
    final lastActiveAt = raw['lastActiveAt'] != null
        ? (DateTime.tryParse(raw['lastActiveAt'].toString())?.toUtc())
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
          otherUserIsOnline: current.otherUserId == userId
              ? isOnline
              : current.otherUserIsOnline,
          otherUserLastActiveAt: current.otherUserId == userId
              ? lastActiveAt
              : current.otherUserLastActiveAt,
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

  void _removeMessage(int messageId) {
    if (!mounted) return;

    final current = List<MessageItem>.from(
      state.messages.valueOrNull ?? const <MessageItem>[],
    );

    final next = current.where((m) => m.id != messageId).toList(growable: false);

    state = state.copyWith(
      messages: AsyncData(List<MessageItem>.unmodifiable(next)),
    );
  }

  void _upsertMessage(MessageItem item) {
    if (!mounted) return;

    final current = List<MessageItem>.from(
      state.messages.valueOrNull ?? const <MessageItem>[],
    );

    final index = _findMessageIndexForMerge(current, item);

    if (index >= 0) {
      final existing = current[index];
      current[index] = item.copyWith(
        clientTag: item.clientTag ?? existing.clientTag,
      );
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

  void _replaceOptimisticMessage({
    required int tempId,
    required String? clientTag,
    required MessageItem serverItem,
  }) {
    if (!mounted) return;

    final current = List<MessageItem>.from(
      state.messages.valueOrNull ?? const <MessageItem>[],
    );

    int index = current.indexWhere((m) => m.id == tempId);

    if (index < 0 && clientTag != null && clientTag.trim().isNotEmpty) {
      index = current.indexWhere((m) => m.clientTag == clientTag);
    }

    if (index < 0) {
      index = _findMessageIndexForMerge(current, serverItem);
    }

    if (index >= 0) {
      final existing = current[index];
      current[index] = serverItem.copyWith(
        clientTag: serverItem.clientTag ?? existing.clientTag ?? clientTag,
        isPending: false,
        isFailed: false,
      );
    } else {
      current.add(
        serverItem.copyWith(
          clientTag: serverItem.clientTag ?? clientTag,
          isPending: false,
          isFailed: false,
        ),
      );
    }

    current.sort((a, b) => a.sentAt.compareTo(b.sentAt));

    state = state.copyWith(
      messages: AsyncData(List<MessageItem>.unmodifiable(current)),
    );

    final sessionUserId = ref.read(sessionUserIdProvider);
    ref.read(messagesInboxControllerProvider.notifier).updateConversationFromMessage(
          threadId: serverItem.threadId,
          preview: serverItem.content,
          sentAt: serverItem.sentAt,
          isMine: sessionUserId != null && serverItem.senderId == sessionUserId,
        );
  }

  int _findMessageIndexForMerge(List<MessageItem> items, MessageItem incoming) {
    final directIdIndex = items.indexWhere((m) => m.id == incoming.id);
    if (directIdIndex >= 0) return directIdIndex;

    final incomingTag = incoming.clientTag?.trim();
    if (incomingTag != null && incomingTag.isNotEmpty) {
      final clientTagIndex = items.indexWhere((m) => m.clientTag == incomingTag);
      if (clientTagIndex >= 0) return clientTagIndex;
    }

    final sessionUserId = ref.read(sessionUserIdProvider);
    if (sessionUserId != null) {
      final fallbackIndex = items.indexWhere((m) {
        if (!m.isPending) return false;
        if (m.senderId != sessionUserId) return false;
        if (m.threadId != incoming.threadId) return false;
        if (m.content.trim() != incoming.content.trim()) return false;
        if (m.replyToMessageId != incoming.replyToMessageId) return false;

        final sentDiff = m.sentAt.difference(incoming.sentAt).inSeconds.abs();
        return sentDiff <= 10;
      });

      if (fallbackIndex >= 0) return fallbackIndex;
    }

    return -1;
  }

  bool _containsEquivalentServerMessage(
    List<MessageItem> serverItems,
    MessageItem localItem,
  ) {
    return serverItems.any((server) {
      if (server.id == localItem.id) return true;

      final localTag = localItem.clientTag?.trim();
      final serverTag = server.clientTag?.trim();
      if (localTag != null &&
          localTag.isNotEmpty &&
          serverTag != null &&
          serverTag.isNotEmpty &&
          localTag == serverTag) {
        return true;
      }

      if (localItem.senderId != server.senderId) return false;
      if (localItem.threadId != server.threadId) return false;
      if (localItem.content.trim() != server.content.trim()) return false;
      if (localItem.replyToMessageId != server.replyToMessageId) return false;

      final diff = localItem.sentAt.difference(server.sentAt).inSeconds.abs();
      return diff <= 10;
    });
  }

  void _markMessageFailed(int tempId) {
    if (!mounted) return;

    final current = List<MessageItem>.from(
      state.messages.valueOrNull ?? const <MessageItem>[],
    );

    final index = current.indexWhere((m) => m.id == tempId);
    if (index < 0) return;

    current[index] = current[index].copyWith(
      isPending: false,
      isFailed: true,
    );

    state = state.copyWith(
      messages: AsyncData(List<MessageItem>.unmodifiable(current)),
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
    _hub = null;

    if (hub != null) {
      Future.microtask(() => _shutdownHub(hub, joined: true));
    }

    super.dispose();
  }
}