import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/liked_event.dart';

final likedEventsApiProvider = Provider<LikedEventsApi>((ref) {
  return LikedEventsApi(ref.watch(authorizedDioProvider));
});

class LikedEventsApi {
  final Dio _dio;

  const LikedEventsApi(this._dio);

  Future<List<LikedEventDto>> getLikedEvents() async {
    final response = await _dio.get<List<dynamic>>('/api/events/liked');

    final raw = response.data ?? const [];

    return raw
        .whereType<Map>()
        .map((e) => LikedEventDto.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> likeEvent(int eventId) async {
    await _dio.post('/api/events/$eventId/like');
  }

  Future<void> unlikeEvent(int eventId) async {
    await _dio.delete('/api/events/$eventId/like');
  }
}