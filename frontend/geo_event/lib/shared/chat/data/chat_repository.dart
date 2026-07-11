import '../models/chat_participant.dart';
import '../models/chat_thread_details.dart';
import '../models/conversation_summary.dart';
import '../models/message_item.dart';
import '../models/message_paged_result.dart';
import 'chat_api.dart';

class ChatRepository {
  const ChatRepository(this.api);

  final ChatApi api;

  Future<MessagePagedResult<ConversationSummary>> getThreads({
    int page = 1,
    int pageSize = 20,
    String? searchTerm,
    bool unreadOnly = false,
  }) {
    return api.getThreads(
      page: page,
      pageSize: pageSize,
      searchTerm: searchTerm,
      unreadOnly: unreadOnly,
    );
  }

  Future<void> leaveThread(int threadId) => api.leaveThread(threadId);

  Future<int> getUnreadCount() => api.getUnreadCount();

  Future<Map<String, dynamic>> openDirectThread({
    required int otherUserId,
  }) {
    return api.openDirectThread(otherUserId: otherUserId);
  }

  Future<ChatThreadDetails> getThreadDetails(int threadId) {
    return api.getThreadDetails(threadId);
  }

  Future<MessagePagedResult<MessageItem>> getThreadMessages({
    required int threadId,
    int page = 1,
    int pageSize = 30,
  }) {
    return api.getThreadMessages(
      threadId: threadId,
      page: page,
      pageSize: pageSize,
    );
  }

Future<MessageItem> sendThreadMessage({
  required int threadId,
  required String content,
  int? replyToMessageId,
  String? clientTag,
}) {
  return api.sendThreadMessage(
    threadId: threadId,
    content: content,
    replyToMessageId: replyToMessageId,
    clientTag: clientTag,
  );
}

  Future<MessageItem> editMessage({
    required int messageId,
    required String content,
  }) {
    return api.editMessage(
      messageId: messageId,
      content: content,
    );
  }

  Future<void> deleteMessage(int messageId) => api.deleteMessage(messageId);

  Future<MessageItem> likeMessage(int messageId) => api.likeMessage(messageId);

  Future<MessageItem> unlikeMessage(int messageId) =>
      api.unlikeMessage(messageId);

  Future<void> markThreadRead(int threadId) => api.markThreadRead(threadId);

  Future<List<ChatParticipant>> getThreadParticipants(int threadId) {
    return api.getThreadParticipants(threadId);
  }
}