import '../../events/models/paged_result.dart';
import '../models/reservation.dart';
import '../models/reservation_status.dart';
import 'reservations_api.dart';

class ReservationsRepository {
  final ReservationsApi api;

  const ReservationsRepository(this.api);

  Future<PagedResult<Reservation>> getMyReservations({
    int page = 1,
    int pageSize = 20,
    ReservationStatus? status,
  }) {
    return api.getMyReservations(
      page: page,
      pageSize: pageSize,
      status: status,
    );
  }

  Future<void> cancelReservation(int reservationId) {
    return api.cancelReservation(reservationId);
  }

  Future<Reservation> requestRefund(
    int reservationId, {
    String? reason,
  }) {
    return api.requestRefund(
      reservationId,
      reason: reason,
    );
  }
}