import 'package:dio/dio.dart';

import '../../events/models/paged_result.dart';
import '../models/reservation.dart';

class ReservationsApi {
  final Dio _dio;

  ReservationsApi(this._dio);

  Future<PagedResult<Reservation>> getMyReservations({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/reservations/my',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        'status': ?status,
      },
    );

    return PagedResult.fromJson(response.data!, Reservation.fromJson);
  }

  Future<void> cancelReservation(int reservationId) async {
    await _dio.patch<void>('/api/reservations/$reservationId/cancel');
  }
}