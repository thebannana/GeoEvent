import 'package:dio/dio.dart';

import '../models/public_profile_bundle.dart';
import '../models/public_profile_event.dart';
import '../models/public_profile_user.dart';
import '../models/user_review.dart';

class PublicProfileApi {
  final Dio _dio;

  const PublicProfileApi(this._dio);

  Future<PublicProfileUser> getUser(int userId) async {
    final response = await _dio.get('/api/users/$userId/public');

    return PublicProfileUser.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<List<PublicProfileUser>> getUsers(List<int> ids) async {
    if (ids.isEmpty) return const [];

    final response = await _dio.get(
      '/api/users/public',
      queryParameters: {
        'ids': ids,
      },
    );

    final raw = response.data;
    final data = raw is List<dynamic> ? raw : const <dynamic>[];

    return data
        .map(
          (e) => PublicProfileUser.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  Future<List<PublicProfileEvent>> getUserEvents(int userId) async {
    final response = await _dio.get(
      '/api/public/events',
      queryParameters: {
        'organizerId': userId,
      },
    );

    final raw = response.data;

    List<dynamic> data;
    if (raw is List<dynamic>) {
      data = raw;
    } else if (raw is Map<String, dynamic>) {
      final items = raw['items'];
      data = items is List<dynamic> ? items : const <dynamic>[];
    } else {
      data = const <dynamic>[];
    }

    return data
        .map(
          (e) => PublicProfileEvent.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  Future<List<UserReview>> getUserReviews(int userId) async {
    final response = await _dio.get('/api/users/$userId/reviews');

    final raw = response.data;
    final items = raw is Map<String, dynamic>
        ? (raw['items'] as List<dynamic>? ?? const [])
        : const <dynamic>[];

    return items
        .map(
          (e) => UserReview.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  Future<void> rateUser({
    required int userId,
    required int rating,
    String? comment,
  }) async {
    await _dio.post(
      '/api/users/$userId/rating',
      data: {
        'value': rating,
        'comment': comment?.trim(),
      },
    );
  }

  Future<void> deleteMyReview({
    required int userId,
  }) async {
    await _dio.delete('/api/users/$userId/rating');
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