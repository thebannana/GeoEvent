import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/chat/models/message_item.dart';
import '../../../shared/chat/models/chat_thread_details.dart';

class ChatThreadState {
  final AsyncValue<ChatThreadDetails> details;
  final AsyncValue<List<MessageItem>> messages;
  final bool sending;
  final bool connectingRealtime;
  final bool realtimeConnected;
  final MessageItem? replyingTo;

  const ChatThreadState({
    this.details = const AsyncValue.loading(),
    this.messages = const AsyncValue.loading(),
    this.sending = false,
    this.connectingRealtime = false,
    this.realtimeConnected = false,
    this.replyingTo,
  });

  ChatThreadState copyWith({
    AsyncValue<ChatThreadDetails>? details,
    AsyncValue<List<MessageItem>>? messages,
    bool? sending,
    bool? connectingRealtime,
    bool? realtimeConnected,
    MessageItem? replyingTo,
    bool clearReplyingTo = false,
  }) {
    return ChatThreadState(
      details: details ?? this.details,
      messages: messages ?? this.messages,
      sending: sending ?? this.sending,
      connectingRealtime: connectingRealtime ?? this.connectingRealtime,
      realtimeConnected: realtimeConnected ?? this.realtimeConnected,
      replyingTo: clearReplyingTo ? null : replyingTo ?? this.replyingTo,
    );
  }
}