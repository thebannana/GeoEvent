import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/application/auth_controller.dart';
import '../../../shared/reservations/data/reservations_repository.dart';
import '../../../shared/reservations/models/reservation.dart';
import '../../../shared/reservations/models/reservation_status.dart';
import '../../../shared/reservations/providers/reservation_providers.dart';

class ReservationsState {
  final List<Reservation> items;
  final int page;
  final int pageSize;
  final bool hasMore;
  final bool isFetchingMore;
  final ReservationStatus? statusFilter;

  const ReservationsState({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.hasMore,
    required this.isFetchingMore,
    this.statusFilter,
  });

  const ReservationsState.initial({this.statusFilter})
      : items = const [],
        page = 1,
        pageSize = 20,
        hasMore = true,
        isFetchingMore = false;

  ReservationsState copyWith({
    List<Reservation>? items,
    int? page,
    int? pageSize,
    bool? hasMore,
    bool? isFetchingMore,
    Object? statusFilter = _sentinel,
  }) {
    return ReservationsState(
      items: items ?? this.items,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      statusFilter: identical(statusFilter, _sentinel)
          ? this.statusFilter
          : statusFilter as ReservationStatus?,
    );
  }
}

const _sentinel = Object();

final reservationsControllerProvider =
    AsyncNotifierProvider<ReservationsController, ReservationsState>(
  ReservationsController.new,
);

class ReservationsController extends AsyncNotifier<ReservationsState> {
  late final ReservationsRepository _repository;

  @override
  Future<ReservationsState> build() async {
    ref.watch(sessionUserIdProvider);
    _repository = ref.read(reservationsRepositoryProvider);
    return _loadFirstPage();
  }

  Future<ReservationsState> _loadFirstPage({
    ReservationStatus? status,
  }) async {
    final result = await _repository.getMyReservations(
      page: 1,
      pageSize: 20,
      status: status,
    );

    return ReservationsState(
      items: result.items,
      page: result.page,
      pageSize: result.pageSize,
      hasMore: result.page < result.totalPages,
      isFetchingMore: false,
      statusFilter: status,
    );
  }

  Future<void> refresh() async {
    final currentFilter = state.valueOrNull?.statusFilter;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _loadFirstPage(status: currentFilter),
    );
  }

  Future<void> setStatusFilter(ReservationStatus? status) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _loadFirstPage(status: status),
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isFetchingMore || !current.hasMore) return;

    state = AsyncData(current.copyWith(isFetchingMore: true));

    try {
      final nextPage = current.page + 1;
      final result = await _repository.getMyReservations(
        page: nextPage,
        pageSize: current.pageSize,
        status: current.statusFilter,
      );

      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...result.items],
          page: result.page,
          hasMore: result.page < result.totalPages,
          isFetchingMore: false,
        ),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(isFetchingMore: false));
      rethrow;
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
      refundRequestedAt: DateTime.now(),
    );

    state = AsyncData(current.copyWith(items: optimisticItems));

    try {
      final updated = await _repository.requestRefund(
        reservationId,
        reason: reason,
      );

      final refreshedItems = [...optimisticItems];
      refreshedItems[index] = updated;

      state = AsyncData(current.copyWith(items: refreshedItems));
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
      cancelledAt: DateTime.now(),
    );

    state = AsyncData(current.copyWith(items: updatedItems));

    try {
      await _repository.cancelReservation(reservationId);
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}