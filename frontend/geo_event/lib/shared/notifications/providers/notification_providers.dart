import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/notification_api.dart';
import '../data/notification_repository.dart';
import '../models/notification_item.dart';

final notificationApiProvider = Provider<NotificationApi>((ref) {
  final dio = ref.watch(authorizedDioProvider);
  return NotificationApi(dio);
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final api = ref.watch(notificationApiProvider);
  return NotificationRepository(api);
});

final unreadNotificationCountProvider =
    AsyncNotifierProvider<UnreadNotificationCountController, int>(
  UnreadNotificationCountController.new,
);

class UnreadNotificationCountController extends AsyncNotifier<int> {
  late final NotificationRepository _repository;

  @override
  Future<int> build() async {
    _repository = ref.read(notificationRepositoryProvider);
    return _repository.getUnreadCount();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.getUnreadCount);
  }

  void decrementIfPositive() {
    final current = state.valueOrNull;
    if (current == null || current <= 0) return;
    state = AsyncData(current - 1);
  }

  void resetToZero() {
    state = const AsyncData(0);
  }
}

final notificationsControllerProvider =
    AsyncNotifierProvider<NotificationsController, List<NotificationItem>>(
  NotificationsController.new,
);

class NotificationsController extends AsyncNotifier<List<NotificationItem>> {
  late final NotificationRepository _repository;

  int _page = 1;
  static const int _pageSize = 30;
  bool _hasMore = true;
  bool _isFetchingMore = false;
  bool? _currentIsReadFilter;

  bool get hasMore => _hasMore;
  bool get isFetchingMore => _isFetchingMore;
  bool? get currentIsReadFilter => _currentIsReadFilter;

  @override
  Future<List<NotificationItem>> build() async {
    _repository = ref.read(notificationRepositoryProvider);
    return _loadFirstPage();
  }

  Future<List<NotificationItem>> _loadFirstPage() async {
    final items = await _repository.getNotifications(
      page: 1,
      pageSize: _pageSize,
      isRead: _currentIsReadFilter,
    );

    _page = 1;
    _hasMore = items.length >= _pageSize;
    return items;
  }

  Future<void> refresh({bool? isRead}) async {
    if (isRead != _currentIsReadFilter) {
      _currentIsReadFilter = isRead;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadFirstPage);

    unawaited(ref.read(unreadNotificationCountProvider.notifier).refresh());
  }

  Future<void> loadMore() async {
    if (_isFetchingMore || !_hasMore || state.isLoading) return;

    final currentItems = state.valueOrNull ?? [];
    _isFetchingMore = true;

    try {
      final nextPage = _page + 1;
      final newItems = await _repository.getNotifications(
        page: nextPage,
        pageSize: _pageSize,
        isRead: _currentIsReadFilter,
      );

      _page = nextPage;
      _hasMore = newItems.length >= _pageSize;
      state = AsyncData([...currentItems, ...newItems]);
    } finally {
      _isFetchingMore = false;
    }
  }

  Future<void> markAsRead(int notificationId) async {
    final currentItems = state.valueOrNull;
    if (currentItems == null) return;

    final index = currentItems.indexWhere(
      (item) => item.notificationId == notificationId,
    );
    if (index == -1) return;

    final target = currentItems[index];
    if (target.isRead) return;

    final updated = [...currentItems];
    updated[index] = target.copyWith(
      isRead: true,
      readAt: DateTime.now(),
    );
    state = AsyncData(updated);

    ref.read(unreadNotificationCountProvider.notifier).decrementIfPositive();

    try {
      await _repository.markAsRead(notificationId);
    } catch (_) {
      state = AsyncData(currentItems);
      unawaited(ref.read(unreadNotificationCountProvider.notifier).refresh());
    }
  }

  Future<void> markAllAsRead() async {
    final currentItems = state.valueOrNull;
    if (currentItems == null || currentItems.isEmpty) return;

    final now = DateTime.now();
    final updated = currentItems
        .map((item) => item.isRead
            ? item
            : item.copyWith(
                isRead: true,
                readAt: now,
              ))
        .toList();

    state = AsyncData(updated);
    ref.read(unreadNotificationCountProvider.notifier).resetToZero();

    try {
      await _repository.markAllAsRead();
    } catch (_) {
      state = AsyncData(currentItems);
      unawaited(ref.read(unreadNotificationCountProvider.notifier).refresh());
    }
  }

  Future<void> delete(int notificationId) async {
    final currentItems = state.valueOrNull;
    if (currentItems == null) return;

    final targetIndex = currentItems.indexWhere(
      (item) => item.notificationId == notificationId,
    );
    if (targetIndex == -1) return;

    final target = currentItems[targetIndex];
    final updated = currentItems
        .where((item) => item.notificationId != notificationId)
        .toList();

    state = AsyncData(updated);

    if (!target.isRead) {
      ref.read(unreadNotificationCountProvider.notifier).decrementIfPositive();
    }

    try {
      await _repository.delete(notificationId);
    } catch (_) {
      state = AsyncData(currentItems);
      unawaited(ref.read(unreadNotificationCountProvider.notifier).refresh());
    }
  }

  Future<void> setFilter(bool? isRead) async {
    if (_currentIsReadFilter == isRead && state.hasValue) return;
    _currentIsReadFilter = isRead;
    await refresh();
  }
}