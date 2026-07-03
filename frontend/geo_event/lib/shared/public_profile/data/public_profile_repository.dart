import '../models/public_profile_bundle.dart';
import 'public_profile_api.dart';

class PublicProfileRepository {
  final PublicProfileApi api;

  const PublicProfileRepository(this.api);

  Future<PublicProfileBundle> getProfile(int userId) {
    return api.getProfileBundle(userId);
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