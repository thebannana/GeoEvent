import 'public_profile_event.dart';
import 'public_profile_event_filter.dart';
import 'public_profile_user.dart';
import 'user_review.dart';

class PublicProfileBundle {
  final PublicProfileUser user;

  final List<PublicProfileEvent> events;
  final int eventsPage;
  final bool eventsHasNextPage;
  final PublicProfileEventFilter selectedEventFilter;

  final List<UserReview> reviews;
  final int reviewsPage;
  final bool reviewsHasNextPage;

  const PublicProfileBundle({
    required this.user,
    required this.events,
    required this.eventsPage,
    required this.eventsHasNextPage,
    required this.selectedEventFilter,
    required this.reviews,
    required this.reviewsPage,
    required this.reviewsHasNextPage,
  });

  PublicProfileBundle copyWith({
    PublicProfileUser? user,
    List<PublicProfileEvent>? events,
    int? eventsPage,
    bool? eventsHasNextPage,
    PublicProfileEventFilter? selectedEventFilter,
    List<UserReview>? reviews,
    int? reviewsPage,
    bool? reviewsHasNextPage,
  }) {
    return PublicProfileBundle(
      user: user ?? this.user,
      events: events ?? this.events,
      eventsPage: eventsPage ?? this.eventsPage,
      eventsHasNextPage: eventsHasNextPage ?? this.eventsHasNextPage,
      selectedEventFilter: selectedEventFilter ?? this.selectedEventFilter,
      reviews: reviews ?? this.reviews,
      reviewsPage: reviewsPage ?? this.reviewsPage,
      reviewsHasNextPage: reviewsHasNextPage ?? this.reviewsHasNextPage,
    );
  }
}