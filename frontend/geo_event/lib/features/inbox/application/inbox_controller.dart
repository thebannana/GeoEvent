import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../shared/notifications/data/notification_api.dart';
import '../../../shared/notifications/data/notification_repository.dart';
import '../../../shared/notifications/models/inbox_state.dart';
import '../../../shared/notifications/models/notification_model.dart';
import '../../../shared/notifications/providers/inbox_providers.dart';

final inboxControllerProvider =
    StateNotifierProvider.autoDispose<InboxController, InboxState>((ref) {
  return InboxController(ref);
});

final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(inboxControllerProvider).unreadCount;
});

class InboxController extends StateNotifier<InboxState> {
  InboxController(this.ref) : super(const InboxState.initial());

  final Ref ref;

  NotificationRepository get _repository =>
      ref.read(notificationRepositoryProvider);

  Future<void> loadNotifications() async {
    if (state.isLoading) return;

    state = const InboxState.initial().copyWith(
      status: InboxStatus.loading,
      searchQuery: state.searchQuery,
      filter: state.filter,
      sort: state.sort,
      clearError: true,
    );

    try {
      final notifications = await _repository.getNotifications(page: 1);
      if (!mounted) return;

      state = state.copyWith(
        notifications: notifications,
        status: InboxStatus.loaded,
        hasMore: notifications.length >= NotificationApi.pageSize,
        page: 1,
      );
    } catch (e, st) {
      if (!mounted) return;

      state = state.copyWith(
        status: InboxStatus.error,
        errorMessage: ErrorMapper.toMessage(e, stackTrace: st),
      );
    }
  }

  Future<void> refresh() async {
    if (state.isRefreshing) return;

    final previous = state.notifications;

    state = state.copyWith(
      status: InboxStatus.refreshing,
      clearError: true,
    );

    try {
      final notifications = await _repository.getNotifications(page: 1);
      if (!mounted) return;

      state = state.copyWith(
        notifications: notifications,
        status: InboxStatus.loaded,
        hasMore: notifications.length >= NotificationApi.pageSize,
        page: 1,
      );
    } catch (e, st) {
      if (!mounted) return;

      state = state.copyWith(
        notifications: previous,
        status: previous.isEmpty ? InboxStatus.error : InboxStatus.loaded,
        errorMessage: ErrorMapper.toMessage(e, stackTrace: st),
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;

    final previous = state.notifications;
    final nextPage = state.page + 1;

    state = state.copyWith(
      status: InboxStatus.loadingMore,
      clearError: true,
    );

    try {
      final more = await _repository.getNotifications(page: nextPage);
      if (!mounted) return;

      final merged = _mergeById([...state.notifications, ...more]);

      state = state.copyWith(
        notifications: merged,
        status: InboxStatus.loaded,
        hasMore: more.length >= NotificationApi.pageSize,
        page: nextPage,
      );
    } catch (e, st) {
      if (!mounted) return;

      state = state.copyWith(
        notifications: previous,
        status: InboxStatus.loaded,
        errorMessage: ErrorMapper.toMessage(e, stackTrace: st),
      );
    }
  }

  void setSearch(String value) {
    if (!mounted) return;
    state = state.copyWith(searchQuery: value, clearError: true);
  }

  void setFilter(NotificationFilter value) {
    if (!mounted) return;
    state = state.copyWith(filter: value, clearError: true);
  }

  void setSort(NotificationSort value) {
    if (!mounted) return;
    state = state.copyWith(sort: value, clearError: true);
  }

  Future<void> markAsRead(int notificationId) async {
    final previous = state.notifications;

    final targetExists = previous.any((n) => n.id == notificationId);
    final alreadyRead =
        previous.where((n) => n.id == notificationId).any((n) => n.isRead);
    if (!targetExists || alreadyRead) return;

    state = state.copyWith(
      notifications: previous
          .map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n)
          .toList(growable: false),
      clearError: true,
    );

    try {
      await _repository.markAsRead(notificationId);
    } catch (e, st) {
      if (!mounted) return;

      state = state.copyWith(
        notifications: previous,
        errorMessage: ErrorMapper.toMessage(e, stackTrace: st),
      );
    }
  }

  Future<void> markAllAsRead() async {
    final previous = state.notifications;

    state = state.copyWith(
      notifications: previous
          .map((n) => n.copyWith(isRead: true))
          .toList(growable: false),
      clearError: true,
    );

    try {
      await _repository.markAllAsRead();
    } catch (e, st) {
      if (!mounted) return;

      state = state.copyWith(
        notifications: previous,
        errorMessage: ErrorMapper.toMessage(e, stackTrace: st),
      );
    }
  }

  Future<void> deleteNotification(int notificationId) async {
    final previous = state.notifications;

    state = state.copyWith(
      notifications: previous
          .where((n) => n.id != notificationId)
          .toList(growable: false),
      clearError: true,
    );

    try {
      await _repository.deleteNotification(notificationId);
    } catch (e, st) {
      if (!mounted) return;

      state = state.copyWith(
        notifications: previous,
        errorMessage: ErrorMapper.toMessage(e, stackTrace: st),
      );
    }
  }

  Future<void> deleteAll() async {
    final previous = state.notifications;

    state = state.copyWith(
      notifications: const [],
      clearError: true,
    );

    try {
      await _repository.deleteAllNotifications();
    } catch (e, st) {
      if (!mounted) return;

      state = state.copyWith(
        notifications: previous,
        errorMessage: ErrorMapper.toMessage(e, stackTrace: st),
      );
    }
  }

  void clearError() {
    if (!mounted) return;
    state = state.copyWith(clearError: true);
  }

  void onPushNotification(NotificationModel notification) {
    if (!mounted) return;

    final next = [
      notification,
      ...state.notifications.where((n) => n.id != notification.id),
    ];

    state = state.copyWith(
      notifications: next,
      status: state.status == InboxStatus.initial ? InboxStatus.loaded : null,
    );
  }

  List<NotificationModel> _mergeById(List<NotificationModel> items) {
    final map = <int, NotificationModel>{};

    for (final item in items) {
      map[item.id] = item;
    }

    final merged = map.values.toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return merged;
  }
}