import 'package:dio/dio.dart';

import '../models/chat_participant.dart';
import '../models/chat_thread_details.dart';
import '../models/conversation_summary.dart';
import '../models/message_item.dart';

class ChatApi {
  final Dio dio;

  const ChatApi(this.dio);

  Future<List<ConversationSummary>> getThreads() async {
    final response = await dio.get('/api/messages/threads');
    final data = response.data;

    if (data is! List) {
      throw const FormatException('Invalid threads response format.');
    }

    return data
        .map((e) => ConversationSummary.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);
  }

  Future<int> getUnreadCount() async {
    final response = await dio.get('/api/messages/unread-count');
    final data = Map<String, dynamic>.from(response.data as Map);
    return (data['unreadCount'] as num?)?.toInt() ?? 0;
  }

  Future<Map<String, dynamic>> openDirectThread({
    required int otherUserId,
  }) async {
    final response = await dio.post(
      '/api/messages/threads/direct/open',
      data: {'otherUserId': otherUserId},
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<ChatThreadDetails> getThreadDetails(int threadId) async {
    final response = await dio.get('/api/messages/threads/$threadId');
    return ChatThreadDetails.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

Future<List<MessageItem>> getThreadMessages(int threadId) async {
  final response = await dio.get('/api/messages/threads/$threadId/messages');
  final data = Map<String, dynamic>.from(response.data as Map);
  final rawItems = data['items'] as List? ?? const [];

  return rawItems
      .map((e) => MessageItem.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(growable: false);
}

  Future<MessageItem> sendThreadMessage({
    required int threadId,
    required String content,
    int? replyToMessageId,
  }) async {
    final response = await dio.post(
      '/api/messages/threads/$threadId/messages',
      data: {
        'content': content.trim(),
        if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      },
    );

    return MessageItem.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> leaveThread(int threadId) async {
  await dio.delete('/api/messages/threads/$threadId/membership');
}

  Future<MessageItem> editMessage({
    required int messageId,
    required String content,
  }) async {
    final response = await dio.patch(
      '/api/messages/messages/$messageId',
      data: {'content': content.trim()},
    );

    return MessageItem.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> deleteMessage(int messageId) async {
    await dio.delete('/api/messages/messages/$messageId');
  }

  Future<MessageItem> likeMessage(int messageId) async {
    final response = await dio.post('/api/messages/messages/$messageId/like');
    return MessageItem.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<MessageItem> unlikeMessage(int messageId) async {
    final response = await dio.delete('/api/messages/messages/$messageId/like');
    return MessageItem.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> markThreadRead(int threadId) async {
    await dio.patch('/api/messages/threads/$threadId/read');
  }

  Future<List<ChatParticipant>> getThreadParticipants(int threadId) async {
    final response = await dio.get('/api/messages/threads/$threadId/participants');
    final data = response.data;

    if (data is! List) {
      throw const FormatException('Invalid participants response format.');
    }

    return data
        .map((e) => ChatParticipant.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);
  }
}