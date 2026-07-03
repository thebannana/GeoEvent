import '../models/public_user_profile.dart';
import 'public_users_api.dart';

class PublicUsersRepository {
  const PublicUsersRepository(this._api);

  final PublicUsersApi _api;

  Future<PublicUserProfileDto> getPublicProfile(int userId) {
    return _api.getPublicProfile(userId);
  }

  Future<Map<int, PublicUserProfileDto>> getPublicProfiles(List<int> ids) {
    return _api.getPublicProfiles(ids);
  }
}