import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../reservations/models/reservation_status.dart';
import 'organizer_reservations_api.dart';

final organizerReservationsRepositoryProvider =
    Provider<OrganizerReservationsRepository>((ref) {
  return OrganizerReservationsRepository(
    ref.watch(organizerReservationsApiProvider),
  );
});

class OrganizerReservationsRepository {
  const OrganizerReservationsRepository(this._api);

  final OrganizerReservationsApi _api;

  Future<PagedOrganizerReservationsResponse> getEventReservations(
    int eventId, {
    int page = 1,
    int pageSize = OrganizerReservationsApi.defaultPageSize,
    ReservationStatus? status,
  }) {
    return _api.getEventReservations(
      eventId,
      page: page,
      pageSize: pageSize,
      status: status,
    );
  }

  Future<void> removeAttendee(
    int eventId,
    int reservationId, {
    String? reason,
  }) {
    return _api.removeAttendee(
      eventId,
      reservationId,
      reason: reason,
    );
  }

  Future<void> markCashCollected(
    int eventId,
    int reservationId,
  ) {
    return _api.markCashCollected(eventId, reservationId);
  }
}