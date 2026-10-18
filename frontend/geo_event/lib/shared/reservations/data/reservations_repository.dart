import '../../events/models/paged_result.dart';
import '../models/reservation.dart';
import '../models/reservation_status.dart';
import 'reservations_api.dart';

class ReservationsRepository {
  final ReservationsApi api;

  const ReservationsRepository(this.api);

  Future<PagedResult<Reservation>> getMyReservations({
    int page = 1,
    int pageSize = ReservationsApi.defaultPageSize,
    ReservationStatus? status,
    int? eventId,
  }) {
    return api.getMyReservations(
      page: page,
      pageSize: pageSize,
      status: status,
      eventId: eventId,
    );
  }

  Future<void> cancelReservation(int reservationId, {String? reason}) {
    return api.cancelReservation(reservationId, reason: reason);
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