import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/organizer_reservation.dart';
import '../../reservations/models/reservation_status.dart';

final organizerReservationsApiProvider =
    Provider<OrganizerReservationsApi>((ref) {
  return OrganizerReservationsApi(ref.watch(authorizedDioProvider));
});

class OrganizerReservationsApi {
  const OrganizerReservationsApi(this._dio);

  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  final Dio _dio;

  Future<PagedOrganizerReservationsResponse> getEventReservations(
    int eventId, {
    int page = 1,
    int pageSize = defaultPageSize,
    ReservationStatus? status,
  }) async {
    final normalizedPage = page <= 0 ? 1 : page;
    final normalizedPageSize = pageSize <= 0
        ? defaultPageSize
        : (pageSize > maxPageSize ? maxPageSize : pageSize);

    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.eventReservations(eventId),
      queryParameters: {
        'page': normalizedPage,
        'pageSize': normalizedPageSize,
        if (status != null) 'status': status.apiValue,
      },
    );

    final data = response.data;
    if (data == null) {
      throw Exception('Reservations response was empty.');
    }

    return PagedOrganizerReservationsResponse.fromJson(data);
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

class PagedOrganizerReservationsResponse {
  const PagedOrganizerReservationsResponse({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  final List<OrganizerReservationDto> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  factory PagedOrganizerReservationsResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map(
              (e) => OrganizerReservationDto.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList(growable: false)
        : <OrganizerReservationDto>[];

    int readInt(dynamic value, int fallback) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    bool readBool(dynamic value, bool fallback) {
      if (value is bool) return value;
      final raw = value?.toString().trim().toLowerCase();
      if (raw == 'true' || raw == '1') return true;
      if (raw == 'false' || raw == '0') return false;
      return fallback;
    }

    final totalCount = readInt(json['totalCount'], items.length);
    final page = readInt(json['page'], 1);
    final pageSize = readInt(
      json['pageSize'],
      items.isEmpty ? OrganizerReservationsApi.defaultPageSize : items.length,
    );
    final totalPages = readInt(
      json['totalPages'],
      pageSize <= 0 ? 0 : (totalCount / pageSize).ceil(),
    );
    final hasNextPage = readBool(json['hasNextPage'], page < totalPages);
    final hasPreviousPage = readBool(json['hasPreviousPage'], page > 1);

    return PagedOrganizerReservationsResponse(
      items: items,
      totalCount: totalCount,
      page: page,
      pageSize: pageSize,
      totalPages: totalPages,
      hasNextPage: hasNextPage,
      hasPreviousPage: hasPreviousPage,
    );
  }
}