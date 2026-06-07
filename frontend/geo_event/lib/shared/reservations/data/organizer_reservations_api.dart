import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/organizer_reservation.dart';

final organizerReservationsApiProvider =
    Provider<OrganizerReservationsApi>((ref) {
  return OrganizerReservationsApi(ref.watch(authorizedDioProvider));
});

class OrganizerReservationsApi {
  final Dio _dio;

  const OrganizerReservationsApi(this._dio);

  Future<List<OrganizerReservationDto>> getEventReservations(int eventId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/reservations/events/$eventId/reservations',
      queryParameters: const {
        'page': 1,
        'pageSize': 100,
      },
    );

    final data = response.data;
    if (data == null) {
      throw Exception('Reservations response was empty.');
    }

    final items = data['items'];
    if (items is! List) {
      return const [];
    }

    return items
        .whereType<Map>()
        .map((e) => OrganizerReservationDto.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}