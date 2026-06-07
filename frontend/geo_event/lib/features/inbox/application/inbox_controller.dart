import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/notifications/data/notification_api.dart';
import '../../../shared/notifications/data/notification_repository.dart';
import '../../../shared/notifications/models/notification_item.dart';

final notificationApiProvider = Provider<NotificationApi>((ref) {
  return NotificationApi(ref.watch(authorizedDioProvider));
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(notificationApiProvider));
});

// ---------------------------------------------------------------------------
// Sort order
// ---------------------------------------------------------------------------
enum NotificationSort { newest, oldest }

// ---------------------------------------------------------------------------
// Filter
// ---------------------------------------------------------------------------
enum NotificationFilter { all, unread, read }

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
class InboxState {
  final AsyncValue<List<NotificationItem>> notifications;
  final NotificationFilter filter;
  final NotificationSort sort;
  final String searchQuery;

  const InboxState({
    required this.notifications,
    this.filter = NotificationFilter.all,
    this.sort = NotificationSort.newest,
    this.searchQuery = '',
  });

  InboxState copyWith({
    AsyncValue<List<NotificationItem>>? notifications,
    NotificationFilter? filter,
    NotificationSort? sort,
    String? searchQuery,
  }) {
    return InboxState(
      notifications: notifications ?? this.notifications,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<NotificationItem> get displayed {
    final all = notifications.valueOrNull ?? [];
    var result = all.where((n) {
      final matchesFilter = switch (filter) {
        NotificationFilter.all => true,
        NotificationFilter.unread => !n.isRead,
        NotificationFilter.read => n.isRead,
      };
      final q = searchQuery.trim().toLowerCase();
      final matchesSearch = q.isEmpty ||
          n.title.toLowerCase().contains(q) ||
          n.description.toLowerCase().contains(q);
      return matchesFilter && matchesSearch;
    }).toList();

    result.sort((a, b) => switch (sort) {
          NotificationSort.newest =>
            b.createdAt.compareTo(a.createdAt),
          NotificationSort.oldest =>
            a.createdAt.compareTo(b.createdAt),
        });
    return result;
  }
}

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------
class InboxController extends Notifier<InboxState> {
  NotificationRepository get _repo =>
      ref.read(notificationRepositoryProvider);

  @override
  InboxState build() {
    Future.microtask(load);
    return const InboxState(notifications: AsyncValue.loading());
  }

  Future<void> load() async {
    state = state.copyWith(notifications: const AsyncValue.loading());
    try {
      final items = await _repo.getNotifications(pageSize: 50);
      state = state.copyWith(notifications: AsyncValue.data(items));
    } catch (e, st) {
      state = state.copyWith(notifications: AsyncValue.error(e, st));
    }
  }

  void setFilter(NotificationFilter f) => state = state.copyWith(filter: f);

  void setSort(NotificationSort s) => state = state.copyWith(sort: s);

  void setSearch(String q) => state = state.copyWith(searchQuery: q);

  Future<void> markAsRead(int id) async {
    await _repo.markAsRead(id);
    final updated = (state.notifications.valueOrNull ?? [])
        .map((n) => n.notificationId == id
            ? n.copyWith(isRead: true, readAt: DateTime.now())
            : n)
        .toList();
    state = state.copyWith(notifications: AsyncValue.data(updated));
  }

  Future<void> markAllAsRead() async {
    await _repo.markAllAsRead();
    final updated = (state.notifications.valueOrNull ?? [])
        .map((n) => n.copyWith(isRead: true, readAt: DateTime.now()))
        .toList();
    state = state.copyWith(notifications: AsyncValue.data(updated));
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    final updated = (state.notifications.valueOrNull ?? [])
        .where((n) => n.notificationId != id)
        .toList();
    state = state.copyWith(notifications: AsyncValue.data(updated));
  }
}

final inboxControllerProvider =
    NotifierProvider<InboxController, InboxState>(InboxController.new);