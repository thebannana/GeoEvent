import '../models/public_profile_bundle.dart';
import 'public_profile_api.dart';

class PublicProfileRepository {
  final PublicProfileApi _api;

  const PublicProfileRepository(this._api);

  Future<PublicProfileBundle> getProfile(int userId) {
    return _api.getProfileBundle(userId);
  }

  Future<void> rateUser({
    required int userId,
    required int rating,
    String? comment,
  }) {
    return _api.rateUser(
      userId: userId,
      rating: rating,
      comment: comment,
    );
  }

  Future<void> deleteMyReview({
    required int userId,
  }) {
    return _api.deleteMyReview(userId: userId);
  }
}