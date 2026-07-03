import 'notification_model.dart';

enum InboxStatus { initial, loading, refreshing, loaded, loadingMore, error }

enum NotificationFilter { all, unread }

enum NotificationSort { newest, oldest }

class InboxState {
  final List<NotificationModel> notifications;
  final InboxStatus status;
  final String? errorMessage;
  final bool hasMore;
  final int page;
  final String searchQuery;
  final NotificationFilter filter;
  final NotificationSort sort;

  const InboxState({
    required this.notifications,
    required this.status,
    required this.hasMore,
    required this.page,
    required this.searchQuery,
    required this.filter,
    required this.sort,
    this.errorMessage,
  });

  const InboxState.initial()
      : notifications = const [],
        status = InboxStatus.initial,
        errorMessage = null,
        hasMore = true,
        page = 1,
        searchQuery = '',
        filter = NotificationFilter.all,
        sort = NotificationSort.newest;

  int get unreadCount => notifications.where((n) => n.isUnread).length;
  bool get isEmpty => notifications.isEmpty;
  bool get isLoading => status == InboxStatus.loading;
  bool get isRefreshing => status == InboxStatus.refreshing;
  bool get isLoadingMore => status == InboxStatus.loadingMore;
  bool get hasError => status == InboxStatus.error;

  List<NotificationModel> get displayed {
    Iterable<NotificationModel> items = notifications;

    if (filter == NotificationFilter.unread) {
      items = items.where((n) => n.isUnread);
    }

    final query = searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      items = items.where((n) {
        return n.title.toLowerCase().contains(query) ||
            n.body.toLowerCase().contains(query) ||
            n.type.name.toLowerCase().contains(query);
      });
    }

    final list = items.toList(growable: false);

    list.sort((a, b) {
      switch (sort) {
        case NotificationSort.newest:
          return b.createdAt.compareTo(a.createdAt);
        case NotificationSort.oldest:
          return a.createdAt.compareTo(b.createdAt);
      }
    });

    return list;
  }

  InboxState copyWith({
    List<NotificationModel>? notifications,
    InboxStatus? status,
    String? errorMessage,
    bool? hasMore,
    int? page,
    String? searchQuery,
    NotificationFilter? filter,
    NotificationSort? sort,
    bool clearError = false,
  }) {
    return InboxState(
      notifications: notifications ?? this.notifications,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
    );
  }
}