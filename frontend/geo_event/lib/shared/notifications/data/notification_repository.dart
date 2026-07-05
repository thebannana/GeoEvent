import '../models/notification_page_result.dart';
import 'notification_api.dart';

class NotificationRepository {
  const NotificationRepository({
    required this.api,
  });

  final NotificationApi api;

  Future<NotificationPageResult> getNotifications({
    int page = 1,
    int pageSize = NotificationApi.defaultPageSize,
  }) {
    return api.getNotifications(
      page: page,
      pageSize: pageSize,
    );
  }

  Future<int> getUnreadCount() {
    return api.getUnreadCount();
  }

  Future<void> markAsRead(int notificationId) {
    return api.markAsRead(notificationId);
  }

  Future<void> markAllAsRead() {
    return api.markAllAsRead();
  }

  Future<void> deleteNotification(int notificationId) {
    return api.deleteNotification(notificationId);
  }

  Future<void> deleteAllNotifications() {
    return api.deleteAllNotifications();
  }
}