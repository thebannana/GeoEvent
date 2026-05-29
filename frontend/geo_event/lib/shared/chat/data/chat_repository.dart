import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/application/auth_controller.dart';
import 'chat_api.dart';
import '../models/conversation_summary.dart';
import '../models/message_item.dart';

final messagesApiProvider = Provider<ChatApi>((ref) {
  return ChatApi(ref.watch(authorizedDioProvider));
});

final messagesRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(messagesApiProvider));
});

class ChatRepository {
  final ChatApi _api;

  ChatRepository(this._api);

  Future<List<ConversationSummary>> getConversations() {
    return _api.getConversations();
  }

  Future<int> getUnreadCount() {
    return _api.getUnreadCount();
  }

  Future<List<MessageItem>> getConversation({
    required int otherUserId,
    int? eventId,
  }) {
    return _api.getConversation(
      otherUserId: otherUserId,
      eventId: eventId,
    );
  }

  Future<MessageItem> sendMessage({
    required int recipientId,
    required String content,
    int? eventId,
  }) {
    return _api.sendMessage(
      recipientId: recipientId,
      content: content,
      eventId: eventId,
    );
  }

  Future<MessageItem> editMessage({
    required int messageId,
    required String content,
  }) {
    return _api.editMessage(
      messageId: messageId,
      content: content,
    );
  }

  Future<void> deleteMessage(int messageId) {
    return _api.deleteMessage(messageId);
  }

  Future<MessageItem> likeMessage(int messageId) {
    return _api.likeMessage(messageId);
  }

  Future<MessageItem> unlikeMessage(int messageId) {
    return _api.unlikeMessage(messageId);
  }

  Future<MessageItem> markMessageAsRead(int messageId) {
    return _api.markMessageAsRead(messageId);
  }

  Future<void> markConversationAsRead({required int otherUserId}) {
    return _api.markConversationAsRead(otherUserId: otherUserId);
  }
}