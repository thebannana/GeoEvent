import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../events/models/paged_result.dart';
import '../models/reservation.dart';
import '../models/reservation_query.dart';
import '../models/reservation_status.dart';

class ReservationsApi {
  final Dio _dio;

  static const int maxPageSize = 50;
  static const int defaultPageSize = 20;

  const ReservationsApi(this._dio);

  Future<PagedResult<Reservation>> getMyReservations({
    int page = 1,
    int pageSize = defaultPageSize,
    ReservationStatus? status,
    int? eventId,
  }) async {
    final query = ReservationsQuery(
      page: page,
      pageSize: pageSize,
      status: status,
      eventId: eventId,
    );

    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.myReservations,
      queryParameters: query.toQueryParameters(),
    );

    final data = response.data;
    if (data == null) {
      throw Exception('Reservations response was empty.');
    }

    return PagedResult<Reservation>.fromJson(data, Reservation.fromJson);
  }

  Future<void> cancelReservation(int reservationId) async {
    await _dio.patch<void>(ApiEndpoints.cancelReservation(reservationId));
  }

  Future<Reservation> requestRefund(
    int reservationId, {
    String? reason,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.requestRefund(reservationId),
      data: {
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );

    final data = response.data;
    if (data == null) {
      throw Exception('Refund request response was empty.');
    }

    return Reservation.fromJson(data);
  }
}