import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/event_reservations/data/organizer_reservations_api.dart';
import '../../../shared/event_reservations/data/organizer_reservations_repository.dart';
import '../../../shared/event_reservations/models/event_reservations_state.dart';
import '../../../shared/event_reservations/models/organizer_reservation.dart';
import '../../../../shared/reservations/models/reservation_status.dart';


class EventReservationsController
    extends StateNotifier<EventReservationsState> {
  EventReservationsController({
    required this.eventId,
    required this.repository,
  }) : super(const EventReservationsState());

  final int eventId;
  final OrganizerReservationsRepository repository;

  Future<void> loadInitial({
    ReservationStatus? status,
    bool force = false,
  }) async {
    if (state.isInitialLoading) return;
    if (state.hasLoadedOnce && !force && state.status == status) return;

    state = state.copyWith(
      isInitialLoading: true,
      hasLoadedOnce: true,
      items: force ? const [] : state.items,
      page: 0,
      totalCount: 0,
      totalPages: 0,
      hasNextPage: true,
      status: status,
      clearErrorMessage: true,
    );

    try {
      final result = await repository.getEventReservations(
        eventId,
        page: 1,
        pageSize: OrganizerReservationsApi.defaultPageSize,
        status: status,
      );

      state = state.copyWith(
        isInitialLoading: false,
        items: _dedupeByReservationId(result.items),
        page: result.page,
        pageSize: result.pageSize,
        totalCount: result.totalCount,
        totalPages: result.totalPages,
        hasNextPage: result.hasNextPage,
        status: status,
        clearErrorMessage: true,
      );
    } catch (e) {
      state = state.copyWith(
        isInitialLoading: false,
        errorMessage: _normalizeError(e),
      );
    }
  }

  Future<void> refresh() async {
    if (state.isRefreshing || state.isInitialLoading) return;

    state = state.copyWith(
      isRefreshing: true,
      clearErrorMessage: true,
    );

    try {
      final result = await repository.getEventReservations(
        eventId,
        page: 1,
        pageSize: state.pageSize <= 0
            ? OrganizerReservationsApi.defaultPageSize
            : state.pageSize,
        status: state.status,
      );

      state = state.copyWith(
        isRefreshing: false,
        hasLoadedOnce: true,
        items: _dedupeByReservationId(result.items),
        page: result.page,
        pageSize: result.pageSize,
        totalCount: result.totalCount,
        totalPages: result.totalPages,
        hasNextPage: result.hasNextPage,
        clearErrorMessage: true,
      );
    } catch (e) {
      state = state.copyWith(
        isRefreshing: false,
        errorMessage: _normalizeError(e),
      );
    }
  }

  Future<void> loadNextPage() async {
    if (state.isInitialLoading || state.isRefreshing || state.isLoadingMore) {
      return;
    }
    if (!state.hasLoadedOnce || !state.hasNextPage) return;

    state = state.copyWith(
      isLoadingMore: true,
      clearErrorMessage: true,
    );

    try {
      final nextPage = state.page + 1;

      final result = await repository.getEventReservations(
        eventId,
        page: nextPage,
        pageSize: state.pageSize <= 0
            ? OrganizerReservationsApi.defaultPageSize
            : state.pageSize,
        status: state.status,
      );

      final merged = _dedupeByReservationId([
        ...state.items,
        ...result.items,
      ]);

      state = state.copyWith(
        isLoadingMore: false,
        items: merged,
        page: result.page,
        pageSize: result.pageSize,
        totalCount: result.totalCount,
        totalPages: result.totalPages,
        hasNextPage: result.hasNextPage,
        clearErrorMessage: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: _normalizeError(e),
      );
    }
  }

  Future<void> applyStatusFilter(ReservationStatus? status) async {
    await loadInitial(status: status, force: true);
  }

  Future<void> clearStatusFilter() async {
    await loadInitial(force: true);
  }

  Future<void> removeAttendee(
    int reservationId, {
    String? reason,
  }) async {
    state = state.copyWith(
      removing: true,
      removingReservationId: reservationId,
      clearErrorMessage: true,
    );

    try {
      await repository.removeAttendee(
        eventId,
        reservationId,
        reason: reason,
      );

      final updatedItems = state.items
          .where((e) => e.reservationId != reservationId)
          .toList(growable: false);

      state = state.copyWith(
        removing: false,
        clearRemovingReservationId: true,
        items: updatedItems,
        totalCount: state.totalCount > 0 ? state.totalCount - 1 : 0,
        clearErrorMessage: true,
      );
    } catch (e) {
      state = state.copyWith(
        removing: false,
        clearRemovingReservationId: true,
        errorMessage: _normalizeError(e),
      );
    }
  }

  Future<void> markCashCollected(int reservationId) async {
    state = state.copyWith(
      markingCashCollected: true,
      cashCollectionReservationId: reservationId,
      clearErrorMessage: true,
    );

    try {
      await repository.markCashCollected(eventId, reservationId);
      await refresh();

      state = state.copyWith(
        markingCashCollected: false,
        clearCashCollectionReservationId: true,
        clearErrorMessage: true,
      );
    } catch (e) {
      state = state.copyWith(
        markingCashCollected: false,
        clearCashCollectionReservationId: true,
        errorMessage: _normalizeError(e),
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearErrorMessage: true);
  }

  static String _normalizeError(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }

  static List<OrganizerReservationDto> _dedupeByReservationId(
    List<OrganizerReservationDto> items,
  ) {
    final map = <int, OrganizerReservationDto>{};
    for (final item in items) {
      map[item.reservationId] = item;
    }
    return map.values.toList(growable: false);
  }
}