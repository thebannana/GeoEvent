import '../../events/models/paged_result.dart';
import '../models/reservation.dart';
import 'reservations_api.dart';

class ReservationsRepository {
  final ReservationsApi _api;

  ReservationsRepository(this._api);

  Future<PagedResult<Reservation>> getMyReservations({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) =>
      _api.getMyReservations(
        page: page,
        pageSize: pageSize,
        status: status,
      );

  Future<void> cancelReservation(int reservationId) =>
      _api.cancelReservation(reservationId);
}