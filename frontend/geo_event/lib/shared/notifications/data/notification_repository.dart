import '../models/notification_model.dart';
import 'notification_api.dart';

class NotificationRepository {
  const NotificationRepository({
    required this.api,
  });

  final NotificationApi api;

  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int pageSize = NotificationApi.pageSize,
  }) {
    return api.getNotifications(
      page: page,
      pageSize: pageSize,
    );
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