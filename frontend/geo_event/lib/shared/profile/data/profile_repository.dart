import '../models/activity_log.dart';
import '../models/user_profile.dart';
import 'profile_api.dart';

class ProfileRepository {
  final ProfileApi api;

  ProfileRepository(this.api);

  Future<UserProfile> getProfile() => api.getMe();

  Future<UserProfile> updateProfile({
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? imageUrl,
  }) {
    return api.updateMe(
      username: username,
      email: email,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      imageUrl: imageUrl,
    );
  }

  Future<String> uploadProfileImage(String filePath) {
    return api.uploadProfileImage(filePath);
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
}