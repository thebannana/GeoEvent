import '../models/public_user_profile.dart';
import '../models/user_profile.dart';
import 'profile_api.dart';

class ProfileRepository {
  const ProfileRepository(this.api);

  final ProfileApi api;

  Future<UserProfile> getProfile() {
    return api.getMe();
  }

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

  Future<void> revokeAllSessions() {
    return api.revokeAllSessions();
  }

  Future<PublicUserProfileDto> getPublicProfile(int userId) {
    return api.getPublicProfile(userId);
  }
}