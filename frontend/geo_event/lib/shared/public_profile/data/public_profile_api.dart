import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../models/paged_response.dart';
import '../models/public_profile_bundle.dart';
import '../models/public_profile_event.dart';
import '../models/public_profile_event_filter.dart';
import '../models/public_profile_user.dart';
import '../models/user_review.dart';

class PublicProfileApi {
  static const int maxPageSize = 50;

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

  int _normalizePageSize(int pageSize) => pageSize.clamp(1, maxPageSize);

  Map<String, dynamic> _buildEventQueryParams({
    required int userId,
    required int page,
    required int pageSize,
    required PublicProfileEventFilter filter,
  }) {
    final now = DateTime.now().toUtc();

    final params = <String, dynamic>{
      'organizerId': userId,
      'page': page < 1 ? 1 : page,
      'pageSize': _normalizePageSize(pageSize),
    };

    switch (filter) {
      case PublicProfileEventFilter.all:
        break;
      case PublicProfileEventFilter.upcoming:
        params['fromDate'] = now.toIso8601String();
        break;
      case PublicProfileEventFilter.past:
        params['toDate'] = now.toIso8601String();
        break;
      case PublicProfileEventFilter.free:
        params['maxPrice'] = 0;
        break;
      case PublicProfileEventFilter.paid:
        params['minPrice'] = 0.01;
        break;
    }

    return params;
  }

  Future<PagedResponse<PublicProfileEvent>> getUserEvents({
    required int userId,
    required PublicProfileEventFilter filter,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.publicEventsBase,
      queryParameters: _buildEventQueryParams(
        userId: userId,
        page: page,
        pageSize: pageSize,
        filter: filter,
      ),
    );

    final raw = response.data;
    if (raw is Map<String, dynamic>) {
      return PagedResponse<PublicProfileEvent>.fromJson(
        raw,
        PublicProfileEvent.fromJson,
      );
    }
    if (raw is Map) {
      return PagedResponse<PublicProfileEvent>.fromJson(
        Map<String, dynamic>.from(raw),
        PublicProfileEvent.fromJson,
      );
    }

    throw Exception('Paged events response was invalid.');
  }

  Future<PagedResponse<UserReview>> getUserReviews({
    required int userId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.userReviews(userId),
      queryParameters: {
        'page': page < 1 ? 1 : page,
        'pageSize': _normalizePageSize(pageSize),
      },
    );

    final raw = response.data;
    if (raw is Map<String, dynamic>) {
      return PagedResponse<UserReview>.fromJson(raw, UserReview.fromJson);
    }
    if (raw is Map) {
      return PagedResponse<UserReview>.fromJson(
        Map<String, dynamic>.from(raw),
        UserReview.fromJson,
      );
    }

    throw Exception('Paged reviews response was invalid.');
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

  Future<PublicProfileBundle> getProfileBundle(
    int userId, {
    int eventsPage = 1,
    int eventsPageSize = 20,
    PublicProfileEventFilter eventFilter = PublicProfileEventFilter.all,
    int reviewsPage = 1,
    int reviewsPageSize = 20,
  }) async {
    final userFuture = getUser(userId);
    final eventsFuture = getUserEvents(
      userId: userId,
      filter: eventFilter,
      page: eventsPage,
      pageSize: eventsPageSize,
    );
    final reviewsFuture = getUserReviews(
      userId: userId,
      page: reviewsPage,
      pageSize: reviewsPageSize,
    );

    final results = await Future.wait([
      userFuture,
      eventsFuture,
      reviewsFuture,
    ]);

    final user = results[0] as PublicProfileUser;
    final events = results[1] as PagedResponse<PublicProfileEvent>;
    final reviews = results[2] as PagedResponse<UserReview>;

    return PublicProfileBundle(
      user: user,
      events: events.items,
      eventsPage: events.page,
      eventsHasNextPage: events.hasNextPage,
      selectedEventFilter: eventFilter,
      reviews: reviews.items,
      reviewsPage: reviews.page,
      reviewsHasNextPage: reviews.hasNextPage,
    );
  }
}