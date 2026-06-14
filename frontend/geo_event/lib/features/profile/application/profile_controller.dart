import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../features/auth/application/auth_controller.dart';
import '../../../shared/profile/models/user_profile.dart';
import '../../../shared/profile/providers/profile_providers.dart';

final profileControllerProvider =
    AsyncNotifierProvider.autoDispose<ProfileController, UserProfile>(
  ProfileController.new,
);

class ProfileController extends AutoDisposeAsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() async {
    final authState = ref.watch(authStateProvider);
    final userId = authState.user?.userId;

    if (!authState.isAuthenticated || userId == null) {
      throw Exception('Not authenticated.');
    }

    return ref.read(profileRepositoryProvider).getProfile();
  }

  Future<void> refreshProfile() async {
    final authState = ref.read(authStateProvider);
    if (!authState.isAuthenticated || authState.user?.userId == null) {
      state = AsyncValue.error(
        Exception('Not authenticated.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).getProfile(),
    );
  }

  Future<bool> updateProfile({
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? imageUrl,
  }) async {
    final result = await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).updateProfile(
            username: username,
            email: email,
            firstName: firstName,
            lastName: lastName,
            phoneNumber: phoneNumber,
            imageUrl: imageUrl,
          ),
    );

    state = result;
    return !result.hasError;
  }

  Future<String> uploadProfileImage(XFile file) async {
    return ref.read(profileRepositoryProvider).uploadProfileImage(file.path);
  }

  Future<void> revokeAllSessions() async {
    await ref.read(profileRepositoryProvider).revokeAllSessions();
  }
}