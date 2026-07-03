import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../models/ticket_models.dart';

class TicketsApi {
  const TicketsApi(this.dio);

  final Dio dio;

  Future<List<EventTicketItem>> getEventTickets(int eventId) async {
    final response = await dio.get(ApiEndpoints.eventTickets(eventId));
    final raw = response.data;

    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => EventTicketItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    if (raw is Map) {
      final map = raw is Map<String, dynamic>
          ? raw
          : Map<String, dynamic>.from(raw);
      final items = map['items'] ?? map['Items'] ?? map['data'] ?? map['Data'];

      if (items is List) {
        return items
            .whereType<Map>()
            .map((e) => EventTicketItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }

    return const [];
  }

  Future<ReservationItem> createReservation(
    CreateReservationRequest payload,
  ) async {
    final response = await dio.post(
      ApiEndpoints.reservations,
      data: payload.toJson(),
    );
    return _parseReservation(
      response.data,
      'Invalid reservation response format.',
    );
  }

  Future<PayPalOrderResponse> createPayPalOrder(int reservationId) async {
    final response = await dio.post(
      ApiEndpoints.createPayPalOrder(reservationId),
    );

    final raw = response.data;
    if (raw is Map<String, dynamic>) {
      return PayPalOrderResponse.fromJson(raw);
    }
    if (raw is Map) {
      return PayPalOrderResponse.fromJson(Map<String, dynamic>.from(raw));
    }

    throw const FormatException('Invalid PayPal order response format.');
  }

  Future<ReservationItem> capturePayPalOrder(
    int reservationId,
    String orderId,
  ) async {
    final response = await dio.post(
      ApiEndpoints.capturePayPalOrder(reservationId),
      data: CapturePayPalOrderRequest(orderId: orderId).toJson(),
    );
    return _parseReservation(
      response.data,
      'Invalid PayPal capture response format.',
    );
  }

  Future<ReservationItem> confirmReservation(
    int reservationId,
    ConfirmReservationRequest payload,
  ) async {
    final response = await dio.post(
      ApiEndpoints.confirmReservation(reservationId),
      data: payload.toJson(),
    );
    return _parseReservation(
      response.data,
      'Invalid reservation confirmation response format.',
    );
  }

  Future<ReservationItem> cashConfirmReservation(int reservationId) async {
    final response = await dio.post(
      ApiEndpoints.cashConfirmReservation(reservationId),
    );
    return _parseReservation(
      response.data,
      'Invalid cash confirmation response format.',
    );
  }

  Future<void> cancelReservation(int reservationId) async {
    await dio.patch(ApiEndpoints.cancelReservation(reservationId));
  }

  Future<ReservationItem> requestRefund(
    int reservationId, {
    String? reason,
  }) async {
    final response = await dio.post(
      ApiEndpoints.requestRefund(reservationId),
      data: {
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );

    return _parseReservation(
      response.data,
      'Invalid refund request response format.',
    );
  }

  Future<EventReservationSummaryItem?> getEventReservationSummary(
    int eventId,
  ) async {
    final response = await dio.get(
      ApiEndpoints.eventReservationSummary(eventId),
    );

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

  Future<PagedResponse<EventAttendeeItem>> getEventAttendees(
    int eventId, {
    int page = 1,
    int pageSize = 100,
  }) async {
    final response = await dio.get(
      ApiEndpoints.publicEventAttendees(eventId),
      queryParameters: {'page': page, 'pageSize': pageSize},
    );

    final raw = response.data;

    if (raw is List) {
      final items = raw
          .whereType<Map>()
          .map((e) => EventAttendeeItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      return PagedResponse<EventAttendeeItem>(
        items: items,
        totalCount: items.length,
        page: page,
        pageSize: pageSize,
      );
    }

    if (raw is Map<String, dynamic>) {
      return PagedResponse<EventAttendeeItem>.fromJson(
        raw,
        EventAttendeeItem.fromJson,
      );
    }

    if (raw is Map) {
      return PagedResponse<EventAttendeeItem>.fromJson(
        Map<String, dynamic>.from(raw),
        EventAttendeeItem.fromJson,
      );
    }

    return PagedResponse<EventAttendeeItem>(
      items: const [],
      totalCount: 0,
      page: page,
      pageSize: pageSize,
    );
  }

  ReservationItem _parseReservation(dynamic raw, String message) {
    if (raw is Map<String, dynamic>) {
      return ReservationItem.fromJson(raw);
    }
    if (raw is Map) {
      return ReservationItem.fromJson(Map<String, dynamic>.from(raw));
    }
    throw FormatException(message);
  }
}