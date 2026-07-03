import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../models/public_profile_bundle.dart';
import '../models/public_profile_event.dart';
import '../models/public_profile_user.dart';
import '../models/user_review.dart';

class PublicProfileApi {
  final Dio _dio;

  const PublicProfileApi(this._dio);

  Future<PublicProfileUser> getUser(int userId) async {
    final response = await _dio.get(ApiEndpoints.publicUser(userId));

    final raw = response.data;
    if (raw is Map<String, dynamic>) {
      return PublicProfileUser.fromJson(raw);
    }
    if (raw is Map) {
      return PublicProfileUser.fromJson(Map<String, dynamic>.from(raw));
    }

    throw Exception('Public profile user response was empty.');
  }

  Future<List<PublicProfileUser>> getUsers(List<int> ids) async {
    if (ids.isEmpty) return const [];

    final response = await _dio.get<List<dynamic>>(
      ApiEndpoints.publicUsers,
      queryParameters: {'ids': ids},
      options: Options(listFormat: ListFormat.multi),
    );

    final data = response.data ?? const <dynamic>[];

    return data
        .whereType<Map>()
        .map((e) => PublicProfileUser.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<PublicProfileEvent>> getUserEvents(int userId) async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.publicEventsBase,
      queryParameters: {'organizerId': userId},
    );

    final raw = response.data;
    List<dynamic> data;

    if (raw is List) {
      data = raw;
    } else if (raw is Map<String, dynamic>) {
      final items = raw['items'];
      data = items is List ? items : const <dynamic>[];
    } else if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final items = map['items'];
      data = items is List ? items : const <dynamic>[];
    } else {
      data = const <dynamic>[];
    }

    return data
        .whereType<Map>()
        .map((e) => PublicProfileEvent.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<UserReview>> getUserReviews(
    int userId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.userReviews(userId),
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
      },
    );

    final raw = response.data;
    if (raw is Map<String, dynamic>) {
      final items = raw['items'];
      final data = items is List ? items : const <dynamic>[];

      return data
          .whereType<Map>()
          .map((e) => UserReview.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final items = map['items'];
      final data = items is List ? items : const <dynamic>[];

      return data
          .whereType<Map>()
          .map((e) => UserReview.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return const [];
  }

  Future<void> rateUser({
    required int userId,
    required int rating,
    String? comment,
  }) async {
    await _dio.post<void>(
      ApiEndpoints.rateUser(userId),
      data: {
        'value': rating,
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
      },
    );
  }

  Future<void> deleteMyReview({required int userId}) async {
    await _dio.delete<void>(ApiEndpoints.rateUser(userId));
  }

  Future<PublicProfileBundle> getProfileBundle(int userId) async {
    final user = await getUser(userId);
    final events = await getUserEvents(userId);
    final reviews = await getUserReviews(userId);

    return PublicProfileBundle(
      user: user,
      events: events,
      reviews: reviews,
    );
  }
}