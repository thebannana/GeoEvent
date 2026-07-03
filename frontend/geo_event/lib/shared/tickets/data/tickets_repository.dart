import '../models/ticket_models.dart';
import 'tickets_api.dart';

class TicketsRepository {
  const TicketsRepository(this.api);

  final TicketsApi api;

  Future<List<EventTicketItem>> getEventTickets(int eventId) {
    return api.getEventTickets(eventId);
  }

  Future<ReservationItem> createReservation(
    CreateReservationRequest payload,
  ) {
    return api.createReservation(payload);
  }

  Future<PayPalOrderResponse> createPayPalOrder(int reservationId) {
    return api.createPayPalOrder(reservationId);
  }

  Future<ReservationItem> capturePayPalOrder(
    int reservationId,
    String orderId,
  ) {
    return api.capturePayPalOrder(reservationId, orderId);
  }

  Future<ReservationItem> confirmReservation(
    int reservationId,
    ConfirmReservationRequest payload,
  ) {
    return api.confirmReservation(reservationId, payload);
  }

  Future<ReservationItem> cashConfirmReservation(int reservationId) {
    return api.cashConfirmReservation(reservationId);
  }

  Future<void> cancelReservation(int reservationId) {
    return api.cancelReservation(reservationId);
  }

  Future<ReservationItem> requestRefund(
    int reservationId, {
    String? reason,
  }) {
    return api.requestRefund(
      reservationId,
      reason: reason,
    );
  }

  Future<EventReservationSummaryItem?> getEventReservationSummary(
    int eventId,
  ) {
    return api.getEventReservationSummary(eventId);
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