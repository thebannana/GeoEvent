import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/organizer_reservation.dart';
import '../models/reservation_status.dart';

final organizerReservationsApiProvider =
    Provider<OrganizerReservationsApi>((ref) {
  return OrganizerReservationsApi(ref.watch(authorizedDioProvider));
});

class OrganizerReservationsApi {
  const OrganizerReservationsApi(this._dio);

  final Dio _dio;

  Future<List<OrganizerReservationDto>> getEventReservations(
    int eventId, {
    int page = 1,
    int pageSize = 100,
    ReservationStatus? status,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.eventReservations(eventId),
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (status != null) 'status': status.apiValue,
      },
    );

    final data = response.data;
    if (data == null) {
      throw Exception('Reservations response was empty.');
    }

    final items = data['items'];
    if (items is! List) return const [];

    return items
        .whereType<Map>()
        .map(
          (e) => OrganizerReservationDto.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }

  Future<void> removeAttendee(
    int eventId,
    int reservationId, {
    String? reason,
  }) async {
    await _dio.patch(
      ApiEndpoints.removeEventReservation(eventId, reservationId),
      data: reason == null || reason.trim().isEmpty
          ? null
          : {'reason': reason.trim()},
    );
  }

  Future<void> markCashCollected(
    int eventId,
    int reservationId,
  ) async {
    await _dio.patch(
      ApiEndpoints.collectReservationCash(eventId, reservationId),
    );
  }
}