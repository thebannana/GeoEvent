import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../models/my_event_response_dto.dart';
import '../models/paged_response.dart';

class MyEventsApi {
  const MyEventsApi(this.dio);

  final Dio dio;

  Future<PagedResponse<MyEventResponseDto>> getMyEvents({
    int page = 1,
    int pageSize = 20,
    String? searchTerm,
    String? status,
    bool? canViewReservations,
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePageSize = pageSize < 1 ? 20 : (pageSize > 50 ? 50 : pageSize);

    final trimmedSearch = searchTerm?.trim();
    final trimmedStatus = status?.trim();

    final response = await dio.get(
      ApiEndpoints.myEvents,
      queryParameters: {
        'page': safePage,
        'pageSize': safePageSize,
        'sortBy': 'StartDateTime',
        'sortDescending': true,
        if (trimmedSearch != null && trimmedSearch.isNotEmpty)
          'searchTerm': trimmedSearch,
        if (trimmedStatus != null &&
            trimmedStatus.isNotEmpty &&
            trimmedStatus.toLowerCase() != 'all')
          'status': trimmedStatus,
        'canViewReservations': ?canViewReservations,
      },
    );

    final data = response.data;
    if (data is! Map) {
      return const PagedResponse<MyEventResponseDto>(
        items: [],
        totalCount: 0,
        page: 1,
        pageSize: 20,
      );
    }

    final map = Map<String, dynamic>.from(data);
    final rawItems = map['items'] ?? map['Items'] ?? const [];

    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((e) => MyEventResponseDto.fromJson(Map<String, dynamic>.from(e)))
            .toList(growable: false)
        : const <MyEventResponseDto>[];

    return PagedResponse<MyEventResponseDto>(
      items: items,
      totalCount: _readInt(map, ['totalCount', 'TotalCount']) ?? items.length,
      page: _readInt(map, ['page', 'Page']) ?? safePage,
      pageSize: _readInt(map, ['pageSize', 'PageSize']) ?? safePageSize,
    );
  }

  Future<void> deleteEvent(int eventId) async {
    await dio.delete(ApiEndpoints.eventById(eventId));
  }

  static int? _readInt(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value != null) {
        final parsed = int.tryParse(value.toString());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }
}