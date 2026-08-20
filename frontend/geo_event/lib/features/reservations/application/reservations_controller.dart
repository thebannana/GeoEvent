import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/application/auth_controller.dart';
import '../../../shared/reservations/data/reservations_repository.dart';
import '../../../shared/reservations/models/reservation_query.dart';
import '../../../shared/reservations/models/reservation_state.dart';
import '../../../shared/reservations/models/reservation_status.dart';
import '../../../shared/reservations/providers/reservation_providers.dart';

final reservationsControllerProvider =
    AsyncNotifierProvider<ReservationsController, ReservationsState>(
  ReservationsController.new,
);

class ReservationsController extends AsyncNotifier<ReservationsState> {
  ReservationsRepository get _repository =>
      ref.read(reservationsRepositoryProvider);

  static const int _defaultPageSize = ReservationsQuery.defaultPageSize;

  @override
  Future<ReservationsState> build() async {
    ref.watch(sessionUserIdProvider);
    return _loadPage(
      const ReservationsQuery(page: 1, pageSize: _defaultPageSize),
      append: false,
      current: null,
    );
  }

  Future<ReservationsState> _loadPage(
    ReservationsQuery query, {
    required bool append,
    ReservationsState? current,
  }) async {
    final result = await _repository.getMyReservations(
      page: query.normalizedPage,
      pageSize: query.normalizedPageSize,
      status: query.status,
      eventId: query.eventId,
    );

    final mergedItems = append && current != null
        ? [...current.items, ...result.items]
        : result.items;

    final hasMore = result.page < result.totalPages;

    return ReservationsState(
      items: mergedItems,
      statusFilter: query.status,
      eventIdFilter: query.eventId,
      isLoading: false,
      isRefreshing: false,
      isFetchingMore: false,
      hasMore: hasMore,
      page: result.page,
      pageSize: result.pageSize,
      totalCount: result.totalCount,
      error: null,
    );
  }

  ReservationsQuery _currentQuery([ReservationsState? current]) {
    final value = current ?? state.valueOrNull;
    return ReservationsQuery(
      status: value?.statusFilter,
      eventId: value?.eventIdFilter,
      page: value?.page ?? 1,
      pageSize: value?.pageSize ?? _defaultPageSize,
    );
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    final query = _currentQuery(current).firstPage();

    if (current != null) {
      state = AsyncData(
        current.copyWith(
          isRefreshing: true,
          isFetchingMore: false,
          clearError: true,
        ),
      );
    } else {
      state = const AsyncLoading();
    }

    state = await AsyncValue.guard(
      () => _loadPage(query, append: false, current: current),
    );
  }

  Future<void> setStatusFilter(ReservationStatus? status) async {
    final current = state.valueOrNull;
    final query = _currentQuery(current).copyWith(
      status: status,
      page: 1,
    );

    if (current != null) {
      state = AsyncData(
        current.copyWith(
          isLoading: true,
          isFetchingMore: false,
          clearError: true,
        ),
      );
    } else {
      state = const AsyncLoading();
    }

    state = await AsyncValue.guard(
      () => _loadPage(query, append: false, current: current),
    );
  }

  Future<void> setEventFilter(int? eventId) async {
    final current = state.valueOrNull;
    final query = _currentQuery(current).copyWith(
      eventId: eventId,
      page: 1,
    );

    if (current != null) {
      state = AsyncData(
        current.copyWith(
          isLoading: true,
          isFetchingMore: false,
          clearError: true,
        ),
      );
    } else {
      state = const AsyncLoading();
    }

    state = await AsyncValue.guard(
      () => _loadPage(query, append: false, current: current),
    );
  }

  Future<void> applyFilters({
    ReservationStatus? status,
    int? eventId,
    bool clearStatus = false,
    bool clearEventId = false,
  }) async {
    final current = state.valueOrNull;
    final base = _currentQuery(current);

    final query = base.copyWith(
      status: clearStatus ? null : status,
      eventId: clearEventId ? null : eventId,
      page: 1,
    );

    if (current != null) {
      state = AsyncData(
        current.copyWith(
          isLoading: true,
          isFetchingMore: false,
          clearError: true,
        ),
      );
    } else {
      state = const AsyncLoading();
    }

    state = await AsyncValue.guard(
      () => _loadPage(query, append: false, current: current),
    );
  }

  Future<void> clearFilters() async {
    await applyFilters(
      clearStatus: true,
      clearEventId: true,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoading || current.isFetchingMore || !current.hasMore) {
      return;
    }

    state = AsyncData(
      current.copyWith(
        isFetchingMore: true,
        clearError: true,
      ),
    );

    final query = _currentQuery(current).copyWith(page: current.page + 1);

    try {
      final next = await _loadPage(
        query,
        append: true,
        current: current,
      );
      state = AsyncData(next);
    } catch (e, st) {
      state = AsyncData(
        current.copyWith(
          isFetchingMore: false,
          error: e.toString(),
        ),
      );
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> requestRefund(
    int reservationId, {
    String? reason,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final index =
        current.items.indexWhere((r) => r.reservationId == reservationId);
    if (index == -1) return;

    final original = current.items[index];
    if (!original.canRequestRefund) return;

    final optimisticItems = [...current.items];
    optimisticItems[index] = original.copyWith(
      refundRequestStatus: 'Pending',
      refundReason: reason?.trim().isEmpty == true ? null : reason?.trim(),
      refundRequestedAt: DateTime.now().toUtc(),
    );

    state = AsyncData(
      current.copyWith(
        items: optimisticItems,
        clearError: true,
      ),
    );

    try {
      final updated = await _repository.requestRefund(
        reservationId,
        reason: reason,
      );

      final latest = state.valueOrNull ?? current;
      final refreshedItems = [...latest.items];
      final latestIndex = refreshedItems.indexWhere(
        (r) => r.reservationId == reservationId,
      );

      if (latestIndex != -1) {
        refreshedItems[latestIndex] = updated;
        state = AsyncData(
          latest.copyWith(
            items: refreshedItems,
            clearError: true,
          ),
        );
      }
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> cancelReservation(int reservationId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final index =
        current.items.indexWhere((r) => r.reservationId == reservationId);
    if (index == -1) return;

    final original = current.items[index];
    if (!original.canBeCancelled) return;

    final updatedItems = [...current.items];
    updatedItems[index] = original.copyWith(
      status: ReservationStatus.cancelled.apiValue,
      cancelledAt: DateTime.now().toUtc(),
    );

    state = AsyncData(
      current.copyWith(
        items: updatedItems,
        clearError: true,
      ),
    );

    try {
      await _repository.cancelReservation(reservationId);
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}