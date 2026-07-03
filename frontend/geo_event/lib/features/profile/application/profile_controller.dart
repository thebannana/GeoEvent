import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../shared/profile/data/profile_repository.dart';
import '../../../shared/profile/models/user_profile.dart';
import '../../../shared/profile/providers/profile_providers.dart';
import '../../auth/application/auth_controller.dart';

final profileControllerProvider =
    AsyncNotifierProvider.autoDispose<ProfileController, UserProfile>(
  ProfileController.new,
);

class ProfileController extends AutoDisposeAsyncNotifier<UserProfile> {
  ProfileRepository get repository => ref.read(profileRepositoryProvider);

  @override
  Future<UserProfile> build() async {
    final authState = ref.watch(authStateProvider);

    if (!authState.isAuthenticated) {
      final fallback = profileFromAuthState();
      if (fallback != null) return fallback;

      throw const AppException(
        type: AppExceptionType.unauthorized,
        message: 'You need to sign in again.',
      );
    }

    return repository.getProfile();
  }

  Future<void> refreshProfile() async {
    final authState = ref.read(authStateProvider);

    if (!authState.isAuthenticated) {
      final fallback = profileFromAuthState();
      if (fallback != null) {
        state = AsyncData(fallback);
      } else {
        state = AsyncError(
          const AppException(
            type: AppExceptionType.unauthorized,
            message: 'You need to sign in again.',
          ),
          StackTrace.current,
        );
      }
      return;
    }

    final previous = state.valueOrNull;
    state = previous != null
        ? AsyncLoading<UserProfile>().copyWithPrevious(AsyncData(previous))
        : const AsyncLoading();

    state = await AsyncValue.guard(repository.getProfile);
  }

  Future<bool> updateProfile({
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String? imageUrl,
  }) async {
    final authState = ref.read(authStateProvider);

    if (!authState.isAuthenticated) {
      final fallback = profileFromAuthState();
      if (fallback != null) {
        state = AsyncData(fallback);
      } else {
        state = AsyncError(
          const AppException(
            type: AppExceptionType.unauthorized,
            message: 'You need to sign in again.',
          ),
          StackTrace.current,
        );
      }
      return false;
    }

    final previous = state.valueOrNull;
    state = previous != null
        ? AsyncLoading<UserProfile>().copyWithPrevious(AsyncData(previous))
        : const AsyncLoading();

    final result = await AsyncValue.guard(
      () => repository.updateProfile(
        username: username.trim(),
        email: email.trim(),
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        phoneNumber: normalize(phoneNumber),
        imageUrl: imageUrl == null ? null : normalize(imageUrl),
      ),
    );

    state = result;
    return !result.hasError;
  }

  Future<String> uploadProfileImage(XFile file) {
    return repository.uploadProfileImage(file.path);
  }

  Future<void> revokeAllSessions() {
    return repository.revokeAllSessions();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  UserProfile? profileFromAuthState() {
    final user = ref.read(authStateProvider).user;
    if (user == null) return null;

    return UserProfile(
      userId: user.userId,
      username: user.username.trim(),
      email: user.email.trim(),
      firstName: user.firstName.trim(),
      lastName: user.lastName.trim(),
      phoneNumber: null,
      imageUrl: normalize(user.imageUrl),
      role: user.role.trim(),
      isVerified: user.isVerified,
      createdAt: user.createdAt,
      averageRating: 0.0,
      ratingsCount: 0,
      myRating: null,
    );
  }

  String? normalize(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}