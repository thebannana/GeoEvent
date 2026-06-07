import 'public_profile_event.dart';
import 'public_profile_user.dart';
import 'user_review.dart';

class PublicProfileBundle {
  final PublicProfileUser user;
  final List<PublicProfileEvent> events;
  final List<UserReview> reviews;

  const PublicProfileBundle({
    required this.user,
    required this.events,
    required this.reviews,
  });
}