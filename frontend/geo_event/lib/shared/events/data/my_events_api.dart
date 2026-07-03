import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../models/my_event_response_dto.dart';

class MyEventsApi {
  const MyEventsApi(this.dio);

  final Dio dio;

  Future<List<MyEventResponseDto>> getMyEvents(int organizerId) async {
    final response = await dio.get(
      ApiEndpoints.myEvents,
      queryParameters: {
        'organizerId': organizerId,
        'page': 1,
        'pageSize': 50,
        'sortBy': 'StartDateTime',
        'sortDescending': true,
      },
    );

    final data = response.data;
    if (data is! Map) {
      return const [];
    }

    final map = Map<String, dynamic>.from(data);
    final rawItems = map['items'] ?? map['Items'] ?? const [];

    if (rawItems is! List) {
      return const [];
    }

    return rawItems
        .whereType<Map>()
        .map((e) => MyEventResponseDto.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> deleteEvent(int eventId) async {
    await dio.delete(ApiEndpoints.eventById(eventId));
  }
}