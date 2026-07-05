import 'notification_model.dart';

class NotificationPageResult {
  final List<NotificationModel> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const NotificationPageResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  const NotificationPageResult.empty({
    this.items = const [],
    this.totalCount = 0,
    this.page = 1,
    this.pageSize = 20,
    this.totalPages = 0,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
  });
}