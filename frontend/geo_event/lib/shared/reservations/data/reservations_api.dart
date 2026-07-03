import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../events/models/paged_result.dart';
import '../models/reservation.dart';
import '../models/reservation_status.dart';

class ReservationsApi {
  final Dio _dio;

  const ReservationsApi(this._dio);

  Future<PagedResult<Reservation>> getMyReservations({
    int page = 1,
    int pageSize = 20,
    ReservationStatus? status,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      if (status != null) 'status': status.apiValue,
    };

    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.myReservations,
      queryParameters: queryParameters,
    );

    final data = response.data;
    if (data == null) {
      throw Exception('Reservations response was empty.');
    }

    return PagedResult.fromJson(data, Reservation.fromJson);
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