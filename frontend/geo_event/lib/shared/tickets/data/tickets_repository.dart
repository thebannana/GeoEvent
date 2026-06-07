import '../../payment/models/complete_checkout_request.dart';
import '../models/ticket_models.dart';
import 'tickets_api.dart';

class TicketsRepository {
  final TicketsApi api;

  const TicketsRepository(this.api);

  Future<List<EventTicketItem>> getEventTickets(int eventId) {
    return api.getEventTickets(eventId);
  }

  Future<ReservationItem> createReservation(CreateReservationRequest payload) {
    return api.createReservation(payload);
  }

  Future<ReservationItem> confirmReservation(
    int reservationId,
    ConfirmReservationRequest payload,
  ) {
    return api.confirmReservation(reservationId, payload);
  }

  Future<EventReservationSummaryItem?> getEventReservationSummary(int eventId) {
    return api.getEventReservationSummary(eventId);
  }

  Future<ReservationItem> completeCheckout(CompleteCheckoutRequest request) {
  return api.completeCheckout(request);
}

  Future<PagedResponse<EventAttendeeItem>> getEventAttendees(
    int eventId, {
    int page = 1,
    int pageSize = 100,
  }) {
    return api.getEventAttendees(
      eventId,
      page: page,
      pageSize: pageSize,
    );
  }
}