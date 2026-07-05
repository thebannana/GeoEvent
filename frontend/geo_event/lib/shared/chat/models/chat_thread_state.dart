import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/chat/models/chat_thread_details.dart';
import '../../../shared/chat/models/message_item.dart';

class ChatThreadState {
  final AsyncValue<ChatThreadDetails> details;
  final AsyncValue<List<MessageItem>> messages;
  final bool sending;
  final bool connectingRealtime;
  final bool realtimeConnected;
  final MessageItem? replyingTo;
  final int messagesPage;
  final int messagesPageSize;
  final int messagesTotalCount;
  final bool hasMoreMessages;
  final bool loadingOlderMessages;

  const ChatThreadState({
    this.details = const AsyncValue.loading(),
    this.messages = const AsyncValue.loading(),
    this.sending = false,
    this.connectingRealtime = false,
    this.realtimeConnected = false,
    this.replyingTo,
    this.messagesPage = 1,
    this.messagesPageSize = 30,
    this.messagesTotalCount = 0,
    this.hasMoreMessages = false,
    this.loadingOlderMessages = false,
  });

  ChatThreadState copyWith({
    AsyncValue<ChatThreadDetails>? details,
    AsyncValue<List<MessageItem>>? messages,
    bool? sending,
    bool? connectingRealtime,
    bool? realtimeConnected,
    MessageItem? replyingTo,
    bool clearReplyingTo = false,
    int? messagesPage,
    int? messagesPageSize,
    int? messagesTotalCount,
    bool? hasMoreMessages,
    bool? loadingOlderMessages,
  }) {
    return ChatThreadState(
      details: details ?? this.details,
      messages: messages ?? this.messages,
      sending: sending ?? this.sending,
      connectingRealtime: connectingRealtime ?? this.connectingRealtime,
      realtimeConnected: realtimeConnected ?? this.realtimeConnected,
      replyingTo: clearReplyingTo ? null : replyingTo ?? this.replyingTo,
      messagesPage: messagesPage ?? this.messagesPage,
      messagesPageSize: messagesPageSize ?? this.messagesPageSize,
      messagesTotalCount: messagesTotalCount ?? this.messagesTotalCount,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      loadingOlderMessages: loadingOlderMessages ?? this.loadingOlderMessages,
    );
  }
}