import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../features/auth/application/auth_controller.dart';
import '../../events/models/create_event_models.dart';
import '../../events/models/paged_result.dart';
import '../../events/providers/event_providers.dart';
import '../data/reservations_api.dart';
import '../data/reservations_repository.dart';
import '../models/reservation.dart';

final reservationsApiProvider = Provider<ReservationsApi>((ref) {
  final dio = ref.watch(authorizedDioProvider);
  return ReservationsApi(dio);
});

final reservationsRepositoryProvider = Provider<ReservationsRepository>((ref) {
  final api = ref.watch(reservationsApiProvider);
  return ReservationsRepository(api);
});

final reservationEventProvider =
    FutureProvider.family<EventItem, int>((ref, eventId) async {
  return ref.read(eventsRepositoryProvider).getEventById(eventId);
});

class ReservationsState {
  final List<Reservation> items;
  final int page;
  final int pageSize;
  final bool hasMore;
  final bool isFetchingMore;
  final String? statusFilter;

  const ReservationsState({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.hasMore,
    required this.isFetchingMore,
    this.statusFilter,
  });

  const ReservationsState.initial({
    this.statusFilter,
  })  : items = const [],
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
    Object? statusFilter = _stateSentinel,
  }) {
    return ReservationsState(
      items: items ?? this.items,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      statusFilter: identical(statusFilter, _stateSentinel)
          ? this.statusFilter
          : statusFilter as String?,
    );
  }
}

const _stateSentinel = Object();

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

  Future<ReservationsState> _loadFirstPage({String? status}) async {
    final result = await _repository.getMyReservations(
      page: 1,
      pageSize: 20,
      status: status,
    );

    return ReservationsState(
      items: result.items,
      page: result.page,
      pageSize: result.pageSize,
      hasMore: _hasMore(result),
      isFetchingMore: false,
      statusFilter: status,
    );
  }

  bool _hasMore(PagedResult<Reservation> result) {
    return result.page < result.totalPages;
  }

  Future<void> refresh() async {
    final currentFilter = state.valueOrNull?.statusFilter;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadFirstPage(status: currentFilter));
  }

  Future<void> setStatusFilter(String? status) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadFirstPage(status: status));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (current.isFetchingMore || !current.hasMore || state.isLoading) return;

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
          pageSize: result.pageSize,
          hasMore: _hasMore(result),
          isFetchingMore: false,
        ),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(isFetchingMore: false));
      rethrow;
    }
  }

  Future<void> cancelReservation(int reservationId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final index = current.items.indexWhere(
      (item) => item.reservationId == reservationId,
    );
    if (index == -1) return;

    final original = current.items[index];
    final updatedItems = [...current.items];
    updatedItems[index] = original.copyWith(
      status: 'Cancelled',
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