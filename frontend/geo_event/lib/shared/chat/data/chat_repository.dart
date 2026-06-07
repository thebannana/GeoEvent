import '../models/chat_participant.dart';
import '../models/chat_thread_details.dart';
import '../models/conversation_summary.dart';
import '../models/message_item.dart';
import 'chat_api.dart';

class ChatRepository {
  final ChatApi api;

  const ChatRepository(this.api);

  Future<List<ConversationSummary>> getThreads() => api.getThreads();

  Future<int> getUnreadCount() => api.getUnreadCount();

  Future<Map<String, dynamic>> openDirectThread({
    required int otherUserId,
  }) =>
      api.openDirectThread(otherUserId: otherUserId);

  Future<ChatThreadDetails> getThreadDetails(int threadId) =>
      api.getThreadDetails(threadId);

  Future<List<MessageItem>> getThreadMessages(int threadId) =>
      api.getThreadMessages(threadId);

  Future<MessageItem> sendThreadMessage({
    required int threadId,
    required String content,
    int? replyToMessageId,
  }) =>
      api.sendThreadMessage(
        threadId: threadId,
        content: content,
        replyToMessageId: replyToMessageId,
      );

  Future<MessageItem> editMessage({
    required int messageId,
    required String content,
  }) =>
      api.editMessage(messageId: messageId, content: content);

  Future<void> deleteMessage(int messageId) => api.deleteMessage(messageId);

  Future<MessageItem> likeMessage(int messageId) => api.likeMessage(messageId);

  Future<MessageItem> unlikeMessage(int messageId) => api.unlikeMessage(messageId);

  Future<void> markThreadRead(int threadId) => api.markThreadRead(threadId);

  Future<List<ChatParticipant>> getThreadParticipants(int threadId) =>
      api.getThreadParticipants(threadId);
}