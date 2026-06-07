import 'package:dio/dio.dart';
import '../models/notification_item.dart';

class NotificationApi {
  final Dio _dio;
  NotificationApi(this._dio);

  Future<List<NotificationItem>> getNotifications({
    int page = 1,
    int pageSize = 30,
    bool? isRead,
  }) async {
    final response = await _dio.get(
      '/api/notifications',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        'isRead': ?isRead,
      },
    );
    final items = (response.data['items'] as List)
        .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return items;
  }

  Future<int> getUnreadCount() async {
    final response = await _dio.get('/api/notifications/unread-count');
    return response.data['unreadCount'] as int;
  }

  Future<void> markAsRead(int notificationId) async {
    await _dio.patch('/api/notifications/$notificationId/read');
  }

  Future<void> markAllAsRead() async {
    await _dio.patch('/api/notifications/read-all');
  }

  Future<void> delete(int notificationId) async {
    await _dio.delete('/api/notifications/$notificationId');
  }
}