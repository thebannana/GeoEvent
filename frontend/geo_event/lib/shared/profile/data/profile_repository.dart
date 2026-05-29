import '../models/activity_log.dart';
import '../models/user_profile.dart';
import 'profile_api.dart';

class ProfileRepository {
  final ProfileApi api;

  ProfileRepository(this.api);

  Future<UserProfile> getProfile() => api.getMe();

  Future<UserProfile> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? imageUrl,
    int? cityId,
  }) {
    return api.updateMe(
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      imageUrl: imageUrl,
      cityId: cityId,
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return api.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<void> revokeAllSessions() => api.revokeAllSessions();

  Future<List<ActivityLog>> getActivityLogs({
    int page = 1,
    int pageSize = 20,
  }) {
    return api.getMyActivityLogs(page: page, pageSize: pageSize);
  }

  Future<List<CitySearchResult>> searchCities(
    String term, {
    int limit = 10,
  }) {
    return api.searchCities(term, limit: limit);
  }
}