import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../events/models/paged_result.dart';
import '../models/liked_event.dart';

final likedEventsApiProvider = Provider<LikedEventsApi>((ref) {
  return LikedEventsApi(ref.watch(authorizedDioProvider));
});

class LikedEventsApi {
  final Dio dio;

  const LikedEventsApi(this.dio);

  Future<PagedResult<LikedEvent>> getLikedEventsPaged({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await dio.get(
      ApiEndpoints.likedEvents,
      queryParameters: {
        'page': page,
        'pageSize': pageSize.clamp(1, 50),
      },
    );

    final raw = response.data;

    if (raw is Map) {
      return PagedResult<LikedEvent>.fromJson(
        Map<String, dynamic>.from(raw),
        LikedEvent.fromJson,
      );
    }

    if (raw is List) {
      final items = raw
          .whereType<Map>()
          .map((e) => LikedEvent.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      return PagedResult<LikedEvent>(
        items: items,
        totalCount: items.length,
        page: page,
        pageSize: pageSize,
        totalPages: 1,
        hasNextPage: false,
        hasPreviousPage: page > 1,
      );
    }

    throw const FormatException('Invalid liked events response format.');
  }

  Future<void> likeEvent(int eventId) async {
    await dio.post(ApiEndpoints.likeEvent(eventId));
  }

  Future<void> unlikeEvent(int eventId) async {
    await dio.delete(ApiEndpoints.likeEvent(eventId));
  }
}