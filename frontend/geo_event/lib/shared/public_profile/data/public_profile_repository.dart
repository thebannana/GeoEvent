import '../models/paged_response.dart';
import '../models/public_profile_bundle.dart';
import '../models/public_profile_event.dart';
import '../models/public_profile_event_filter.dart';
import '../models/user_review.dart';
import 'public_profile_api.dart';

class PublicProfileRepository {
  final PublicProfileApi api;

  const PublicProfileRepository(this.api);

  Future<PublicProfileBundle> getProfile(
    int userId, {
    int eventsPage = 1,
    int eventsPageSize = 20,
    PublicProfileEventFilter eventFilter = PublicProfileEventFilter.all,
    int reviewsPage = 1,
    int reviewsPageSize = 20,
  }) {
    return api.getProfileBundle(
      userId,
      eventsPage: eventsPage,
      eventsPageSize: eventsPageSize,
      eventFilter: eventFilter,
      reviewsPage: reviewsPage,
      reviewsPageSize: reviewsPageSize,
    );
  }

  Future<PagedResponse<PublicProfileEvent>> getUserEventsPage({
    required int userId,
    required int page,
    required PublicProfileEventFilter filter,
    int pageSize = 20,
  }) {
    return api.getUserEvents(
      userId: userId,
      filter: filter,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<PagedResponse<UserReview>> getUserReviewsPage({
    required int userId,
    required int page,
    int pageSize = 20,
  }) {
    return api.getUserReviews(
      userId: userId,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<void> rateUser({
    required int userId,
    required int rating,
    String? comment,
  }) {
    return api.rateUser(
      userId: userId,
      rating: rating,
      comment: comment,
    );
  }

  Future<void> deleteMyReview({
    required int userId,
  }) {
    return api.deleteMyReview(userId: userId);
  }
}