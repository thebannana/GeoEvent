import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../models/notification_model.dart';

class NotificationApi {
  const NotificationApi({required this.authorizedDio});

  final Dio authorizedDio;

  static const int pageSize = 20;

  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int pageSize = NotificationApi.pageSize,
  }) async {
    final response = await authorizedDio.get(
      ApiEndpoints.notifications,
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
      },
    );

    return _parseList(response.data);
  }

  Future<void> markAsRead(int notificationId) async {
    await authorizedDio.patch(
      ApiEndpoints.markNotificationRead(notificationId),
    );
  }

  Future<void> markAllAsRead() async {
    await authorizedDio.patch(ApiEndpoints.markAllNotificationsRead);
  }

  Future<void> deleteNotification(int notificationId) async {
    await authorizedDio.delete(ApiEndpoints.notificationById(notificationId));
  }

  Future<void> deleteAllNotifications() async {
    await authorizedDio.delete(ApiEndpoints.notifications);
  }

  List<NotificationModel> _parseList(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => NotificationModel.fromJson(
                e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e),
              ))
          .toList(growable: false);
    }

    if (raw is Map) {
      final map =
          raw is Map<String, dynamic> ? raw : Map<String, dynamic>.from(raw);

      final items = map['items'] ??
          map['Items'] ??
          map['data'] ??
          map['Data'] ??
          map['results'] ??
          map['Results'];

      if (items is List) {
        return items
            .whereType<Map>()
            .map((e) => NotificationModel.fromJson(
                  e is Map<String, dynamic>
                      ? e
                      : Map<String, dynamic>.from(e),
                ))
            .toList(growable: false);
      }
    }

    return const [];
  }
}