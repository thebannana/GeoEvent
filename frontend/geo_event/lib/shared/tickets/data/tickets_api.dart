import 'package:dio/dio.dart';

import '../../payment/models/complete_checkout_request.dart';
import '../models/ticket_models.dart';

class TicketsApi {
  final Dio dio;

  const TicketsApi(this.dio);

  Future<List<EventTicketItem>> getEventTickets(int eventId) async {
    final response = await dio.get('/api/events/$eventId/tickets');
    final raw = response.data;

    if (raw is! List) return const [];

    return raw
        .whereType<Map>()
        .map((e) => EventTicketItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<ReservationItem> createReservation(
    CreateReservationRequest payload,
  ) async {
    final response = await dio.post(
      '/api/reservations',
      data: payload.toJson(),
    );

    final raw = response.data;
    if (raw is Map<String, dynamic>) {
      return ReservationItem.fromJson(raw);
    }
    if (raw is Map) {
      return ReservationItem.fromJson(Map<String, dynamic>.from(raw));
    }

    throw Exception('Invalid reservation response format.');
  }

  Future<ReservationItem> confirmReservation(
    int reservationId,
    ConfirmReservationRequest payload,
  ) async {
    final response = await dio.post(
      '/api/reservations/$reservationId/confirm',
      data: payload.toJson(),
    );

    final raw = response.data;
    if (raw is Map<String, dynamic>) {
      return ReservationItem.fromJson(raw);
    }
    if (raw is Map) {
      return ReservationItem.fromJson(Map<String, dynamic>.from(raw));
    }

    throw Exception('Invalid reservation confirmation response format.');
  }

  Future<EventReservationSummaryItem?> getEventReservationSummary(
    int eventId,
  ) async {
    final response = await dio.get('/api/reservations/events/$eventId/summary');
    final raw = response.data;

    if (raw is Map<String, dynamic>) {
      return EventReservationSummaryItem.fromJson(raw);
    }
    if (raw is Map) {
      return EventReservationSummaryItem.fromJson(
        Map<String, dynamic>.from(raw),
      );
    }

    return null;
  }

  Future<ReservationItem> completeCheckout(CompleteCheckoutRequest request) async {
  final response = await dio.post(
    '/api/reservations/checkout',
    data: request.toJson(),
  );

  return ReservationItem.fromJson(
    Map<String, dynamic>.from(response.data as Map),
  );
}

  Future<PagedResponse<EventAttendeeItem>> getEventAttendees(
  int eventId, {
  int page = 1,
  int pageSize = 100,
}) async {
  final response = await dio.get(
    '/api/reservations/public/events/$eventId/attendees',
  );

  final raw = response.data;

  if (raw is List) {
    final items = raw
        .whereType<Map>()
        .map((e) => EventAttendeeItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return PagedResponse(
      items: items,
      totalCount: items.length,
      page: 1,
      pageSize: items.length,
    );
  }

  if (raw is Map<String, dynamic>) {
    return PagedResponse.fromJson(raw, EventAttendeeItem.fromJson);
  }

  if (raw is Map) {
    return PagedResponse.fromJson(
      Map<String, dynamic>.from(raw),
      EventAttendeeItem.fromJson,
    );
  }

  return const PagedResponse(
    items: [],
    totalCount: 0,
    page: 1,
    pageSize: 100,
  );
}
}