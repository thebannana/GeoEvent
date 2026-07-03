import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/liked_event.dart';

final likedEventsApiProvider = Provider<LikedEventsApi>((ref) {
  return LikedEventsApi(ref.watch(authorizedDioProvider));
});

class LikedEventsApi {
  final Dio _dio;

  const LikedEventsApi(this._dio);

  Future<List<LikedEvent>> getLikedEvents() async {
  final response = await _dio.get(ApiEndpoints.likedEvents);
  final raw = response.data;

  if (raw is List) {
    return raw
        .whereType<Map>()
        .map((e) => LikedEvent.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  if (raw is Map) {
    final map = Map<String, dynamic>.from(raw);
    final items = map['items'];
    if (items is List) {
      return items
          .whereType<Map>()
          .map((e) => LikedEvent.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  throw const FormatException('Invalid liked events response format.');
}

  Future<void> likeEvent(int eventId) async {
    await _dio.post(ApiEndpoints.likeEvent(eventId));
  }

  Future<void> unlikeEvent(int eventId) async {
    await _dio.delete(ApiEndpoints.likeEvent(eventId));
  }
}