import '../models/paged_response.dart';
import '../models/user_profile.dart';
import 'admin_users_api.dart';

class AdminUsersRepository {
  const AdminUsersRepository(this.api);

  final AdminUsersApi api;

  Future<PagedResponse<UserProfile>> getUsers({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? role,
    bool? isBanned,
  }) {
    return api.getUsers(
      page: page,
      pageSize: pageSize,
      search: search,
      role: role,
      isBanned: isBanned,
    );
  }

  Future<UserProfile> updateUser({
    required int userId,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? imageUrl,
    String? role,
  }) {
    return api.updateUser(
      userId: userId,
      username: username,
      email: email,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      imageUrl: imageUrl,
      role: role,
    );
  }

Future<AdminUserProfileDetails> getUserProfileDetails(int userId) {
  return api.getUserProfileDetails(userId);
}

Future<String> uploadProfileImage(String filePath) {
  return api.uploadProfileImage(filePath);
}

  Future<void> deleteUser(int userId) {
    return api.deleteUser(userId);
  }

  Future<void> banUser(int userId) {
    return api.banUser(userId);
  }

  Future<void> unbanUser(int userId) {
    return api.unbanUser(userId);
  }
}