import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/events/models/paged_result.dart';
import '../../../shared/reservations/data/reservations_api.dart';
import '../../../shared/reservations/data/reservations_repository.dart';
import '../../../shared/reservations/models/reservation.dart';

final reservationsApiProvider = Provider<ReservationsApi>((ref) {
  return ReservationsApi(ref.watch(authorizedDioProvider));
});

final reservationsRepositoryProvider = Provider<ReservationsRepository>((ref) {
  return ReservationsRepository(ref.watch(reservationsApiProvider));
});

class ReservationsState {
  final AsyncValue<PagedResult<Reservation>> paged;
  final String? activeStatus;
  final String searchQuery;

  const ReservationsState({
    this.paged = const AsyncValue.loading(),
    this.activeStatus,
    this.searchQuery = '',
  });

  ReservationsState copyWith({
    AsyncValue<PagedResult<Reservation>>? paged,
    String? Function()? activeStatus,
    String? searchQuery,
  }) {
    return ReservationsState(
      paged: paged ?? this.paged,
      activeStatus:
          activeStatus != null ? activeStatus() : this.activeStatus,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<Reservation> get filteredItems {
    final all = paged.valueOrNull?.items ?? const <Reservation>[];
    final q = searchQuery.trim().toLowerCase();

    if (q.isEmpty) return all;

    return all.where((reservation) {
      return reservation.reservationId.toString().contains(q) ||
          reservation.eventId.toString().contains(q) ||
          reservation.status.toLowerCase().contains(q) ||
          reservation.currency.toLowerCase().contains(q) ||
          (reservation.paymentReference?.toLowerCase().contains(q) ?? false) ||
          (reservation.notes?.toLowerCase().contains(q) ?? false);
    }).toList();
  }
}

class ReservationsController extends Notifier<ReservationsState> {
  ReservationsRepository get _repo => ref.read(reservationsRepositoryProvider);

  @override
  ReservationsState build() {
    Future.microtask(load);
    return const ReservationsState();
  }

  Future<void> load() async {
    state = state.copyWith(paged: const AsyncValue.loading());

    final result = await AsyncValue.guard<PagedResult<Reservation>>(
      () => _repo.getMyReservations(status: state.activeStatus),
    );

    state = state.copyWith(paged: result);
  }

  Future<void> setFilter(String? status) async {
    state = state.copyWith(activeStatus: () => status);
    await load();
  }

  void setSearch(String value) {
    state = state.copyWith(searchQuery: value);
  }

  Future<bool> cancel(int reservationId) async {
    try {
      await _repo.cancelReservation(reservationId);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final reservationsControllerProvider =
    NotifierProvider<ReservationsController, ReservationsState>(
  ReservationsController.new,
);