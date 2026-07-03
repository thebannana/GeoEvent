import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../models/chat_participant.dart';
import '../models/chat_thread_details.dart';
import '../models/conversation_summary.dart';
import '../models/message_item.dart';
import '../models/message_paged_result.dart';

class ChatApi {
  const ChatApi(this.dio);

  final Dio dio;

  Future<List<ConversationSummary>> getThreads() async {
    final response = await dio.get(ApiEndpoints.threads);
    final raw = response.data;

    if (raw is! List) {
      throw const FormatException('Invalid threads response format.');
    }

    return raw
        .whereType<Map>()
        .map((e) => ConversationSummary.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  Future<int> getUnreadCount() async {
    final response = await dio.get(ApiEndpoints.unreadChatCount);
    final raw = response.data;

    if (raw is Map<String, dynamic>) {
      return (raw['unreadCount'] as num?)?.toInt() ?? 0;
    }

    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      return (map['unreadCount'] as num?)?.toInt() ?? 0;
    }

    return 0;
  }

  Future<Map<String, dynamic>> openDirectThread({
    required int otherUserId,
  }) async {
    final response = await dio.post(
      ApiEndpoints.openDirectThread,
      data: {'otherUserId': otherUserId},
    );

    final raw = response.data;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);

    throw const FormatException('Invalid direct thread response format.');
  }

  Future<ChatThreadDetails> getThreadDetails(int threadId) async {
    final response = await dio.get(ApiEndpoints.threadById(threadId));
    return _parseThreadDetails(response.data);
  }

  Future<List<MessageItem>> getThreadMessages(int threadId) async {
    final response = await dio.get(ApiEndpoints.threadMessages(threadId));
    final raw = response.data;

    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => MessageItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    }

    if (raw is Map<String, dynamic>) {
      final paged = MessagePagedResult<MessageItem>.fromJson(
        raw,
        MessageItem.fromJson,
      );
      return paged.items;
    }

    if (raw is Map) {
      final paged = MessagePagedResult<MessageItem>.fromJson(
        Map<String, dynamic>.from(raw),
        MessageItem.fromJson,
      );
      return paged.items;
    }

    throw const FormatException('Invalid thread messages response format.');
  }

  Future<MessageItem> sendThreadMessage({
    required int threadId,
    required String content,
    int? replyToMessageId,
  }) async {
    final response = await dio.post(
      ApiEndpoints.threadMessages(threadId),
      data: {
        'content': content.trim(),
        'replyToMessageId': ?replyToMessageId,
      },
    );

    return _parseMessage(response.data);
  }

  Future<void> leaveThread(int threadId) async {
    await dio.delete(ApiEndpoints.leaveThread(threadId));
  }

  Future<MessageItem> editMessage({
    required int messageId,
    required String content,
  }) async {
    final response = await dio.patch(
      ApiEndpoints.messageById(messageId),
      data: {'content': content.trim()},
    );

    return _parseMessage(response.data);
  }

  Future<void> deleteMessage(int messageId) async {
    await dio.delete(ApiEndpoints.messageById(messageId));
  }

  Future<MessageItem> likeMessage(int messageId) async {
    final response = await dio.post(ApiEndpoints.likeMessage(messageId));
    return _parseMessage(response.data);
  }

  Future<MessageItem> unlikeMessage(int messageId) async {
    final response = await dio.delete(ApiEndpoints.likeMessage(messageId));
    return _parseMessage(response.data);
  }

  Future<void> markThreadRead(int threadId) async {
    await dio.patch(ApiEndpoints.markThreadRead(threadId));
  }

  Future<List<ChatParticipant>> getThreadParticipants(int threadId) async {
    final response = await dio.get(ApiEndpoints.threadParticipants(threadId));
    final raw = response.data;

    if (raw is! List) {
      throw const FormatException('Invalid participants response format.');
    }

    return raw
        .whereType<Map>()
        .map((e) => ChatParticipant.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  ChatThreadDetails _parseThreadDetails(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return ChatThreadDetails.fromJson(raw);
    }
    if (raw is Map) {
      return ChatThreadDetails.fromJson(Map<String, dynamic>.from(raw));
    }
    throw const FormatException('Invalid thread details response format.');
  }

  MessageItem _parseMessage(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return MessageItem.fromJson(raw);
    }
    if (raw is Map) {
      return MessageItem.fromJson(Map<String, dynamic>.from(raw));
    }
    throw const FormatException('Invalid message response format.');
  }
}