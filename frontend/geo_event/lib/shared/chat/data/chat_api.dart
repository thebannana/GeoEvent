import 'package:dio/dio.dart';

import '../models/conversation_summary.dart';
import '../models/message_item.dart';

class ChatApi {
  final Dio _dio;

  ChatApi(this._dio);

  Future<List<ConversationSummary>> getConversations() async {
    final response = await _dio.get('/api/messages/conversations');
    final data = response.data as List;
    return data
        .map((e) => ConversationSummary.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<int> getUnreadCount() async {
    final response = await _dio.get('/api/messages/unread-count');
    return (response.data['unreadCount'] as num).toInt();
  }

  Future<List<MessageItem>> getConversation({
    required int otherUserId,
    int? eventId,
  }) async {
    final response = await _dio.get(
      '/api/messages/conversation/$otherUserId',
      queryParameters: {
        'page': 1,
        'pageSize': 100,
        'sortOrder': 'Oldest',
        if (eventId != null) 'eventId': eventId,
      },
    );

    final items = (response.data['items'] as List?) ?? const [];
    return items
        .map((e) => MessageItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<MessageItem> sendMessage({
    required int recipientId,
    required String content,
    int? eventId,
  }) async {
    final response = await _dio.post(
      '/api/messages',
      data: {
        'recipientId': recipientId,
        'content': content,
        if (eventId != null) 'eventId': eventId,
      },
    );

    return MessageItem.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<MessageItem> editMessage({
    required int messageId,
    required String content,
  }) async {
    final response = await _dio.patch(
      '/api/messages/$messageId',
      data: {
        'content': content,
      },
    );

    return MessageItem.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<void> deleteMessage(int messageId) async {
    await _dio.delete('/api/messages/$messageId');
  }

  Future<MessageItem> likeMessage(int messageId) async {
    final response = await _dio.post('/api/messages/$messageId/like');
    return MessageItem.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<MessageItem> unlikeMessage(int messageId) async {
    final response = await _dio.delete('/api/messages/$messageId/like');
    return MessageItem.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<MessageItem> markMessageAsRead(int messageId) async {
    final response = await _dio.patch('/api/messages/$messageId/read');
    return MessageItem.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<void> markConversationAsRead({required int otherUserId}) async {
    await _dio.patch('/api/messages/conversation/$otherUserId/read-all');
  }
}