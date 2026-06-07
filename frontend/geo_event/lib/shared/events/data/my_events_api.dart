import 'package:dio/dio.dart';

import '../models/my_event_response_dto.dart';

class MyEventsApi {
  final Dio _dio;

  const MyEventsApi(this._dio);

  Future<List<MyEventResponseDto>> getMyEvents(int organizerId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/events/mine',
      queryParameters: {
        'organizerId': organizerId,
        'page': 1,
        'pageSize': 50,
        'sortBy': 'StartDateTime',
        'sortDescending': true,
      },
    );

    final data = response.data ?? const <String, dynamic>{};
    final rawItems = data['items'] ?? data['Items'] ?? const <dynamic>[];

    if (rawItems is! List) {
      return const <MyEventResponseDto>[];
    }

    return rawItems
        .whereType<Map>()
        .map(
          (e) => MyEventResponseDto.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }

  Future<void> deleteEvent(int eventId) async {
  await _dio.delete('/api/events/$eventId');
}
}