import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../models/notification_model.dart';
import '../models/notification_page_result.dart';

class NotificationApi {
  const NotificationApi({required this.authorizedDio});

  final Dio authorizedDio;

  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  Future<NotificationPageResult> getNotifications({
    int page = 1,
    int pageSize = defaultPageSize,
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePageSize = pageSize < 1
        ? defaultPageSize
        : (pageSize > maxPageSize ? maxPageSize : pageSize);

    final response = await authorizedDio.get(
      ApiEndpoints.notifications,
      queryParameters: {
        'page': safePage,
        'pageSize': safePageSize,
      },
    );

    return _parsePage(response.data, requestedPage: safePage, requestedPageSize: safePageSize);
  }

  Future<int> getUnreadCount() async {
    final response =
        await authorizedDio.get(ApiEndpoints.unreadNotificationsCount);
    final raw = response.data;

    if (raw is Map) {
      final map =
          raw is Map<String, dynamic> ? raw : Map<String, dynamic>.from(raw);
      final value = map['unreadCount'] ?? map['UnreadCount'] ?? 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    return 0;
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

  NotificationPageResult _parsePage(
    dynamic raw, {
    required int requestedPage,
    required int requestedPageSize,
  }) {
    if (raw is List) {
      final items = raw
          .whereType<Map>()
          .map(
            (e) => NotificationModel.fromJson(
              e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e),
            ),
          )
          .toList(growable: false);

      final totalCount = items.length;
      final totalPages =
          requestedPageSize <= 0 ? 1 : (totalCount / requestedPageSize).ceil();

      return NotificationPageResult(
        items: items,
        totalCount: totalCount,
        page: requestedPage,
        pageSize: requestedPageSize,
        totalPages: totalPages,
        hasNextPage: requestedPage < totalPages,
        hasPreviousPage: requestedPage > 1,
      );
    }

    if (raw is Map) {
      final map =
          raw is Map<String, dynamic> ? raw : Map<String, dynamic>.from(raw);

      final itemsRaw = map['items'] ??
          map['Items'] ??
          map['data'] ??
          map['Data'] ??
          map['results'] ??
          map['Results'];

      final items = itemsRaw is List
          ? itemsRaw
              .whereType<Map>()
              .map(
                (e) => NotificationModel.fromJson(
                  e is Map<String, dynamic>
                      ? e
                      : Map<String, dynamic>.from(e),
                ),
              )
              .toList(growable: false)
          : const <NotificationModel>[];

      final totalCount = _asInt(
            map['totalCount'] ?? map['TotalCount'],
          ) ??
          items.length;

      final page = _asInt(
            map['page'] ?? map['Page'],
          ) ??
          requestedPage;

      final pageSize = _asInt(
            map['pageSize'] ?? map['PageSize'],
          ) ??
          requestedPageSize;

      final totalPages = _asInt(
            map['totalPages'] ?? map['TotalPages'],
          ) ??
          (pageSize <= 0 ? 0 : (totalCount / pageSize).ceil());

      final hasNextPage = _asBool(
            map['hasNextPage'] ?? map['HasNextPage'],
          ) ??
          page < totalPages;

      final hasPreviousPage = _asBool(
            map['hasPreviousPage'] ?? map['HasPreviousPage'],
          ) ??
          page > 1;

      return NotificationPageResult(
        items: items,
        totalCount: totalCount,
        page: page,
        pageSize: pageSize,
        totalPages: totalPages,
        hasNextPage: hasNextPage,
        hasPreviousPage: hasPreviousPage,
      );
    }

    return NotificationPageResult.empty(
      page: requestedPage,
      pageSize: requestedPageSize,
    );
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  bool? _asBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    final normalized = value.toString().trim().toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
    return null;
  }
}