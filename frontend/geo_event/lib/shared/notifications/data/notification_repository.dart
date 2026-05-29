import '../models/notification_item.dart';
import 'notification_api.dart';

class NotificationRepository {
  final NotificationApi _api;
  NotificationRepository(this._api);

  Future<List<NotificationItem>> getNotifications({
    int page = 1,
    int pageSize = 30,
    bool? isRead,
  }) =>
      _api.getNotifications(page: page, pageSize: pageSize, isRead: isRead);

  Future<int> getUnreadCount() => _api.getUnreadCount();

  Future<void> markAsRead(int id) => _api.markAsRead(id);

  Future<void> markAllAsRead() => _api.markAllAsRead();

  Future<void> delete(int id) => _api.delete(id);
}