import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/errors/app_exceptions.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/admin_profile/data/profile_repository.dart';
import '../../../shared/admin_profile/models/user_profile.dart';
import '../../../shared/admin_profile/providers/profile_providers.dart';
import '../../auth/application/auth_controller.dart';

final profileControllerProvider = StateNotifierProvider.autoDispose<
    ProfileController, AsyncValue<UserProfile>>(
  (ref) => ProfileController(ref),
);

class ProfileController extends StateNotifier<AsyncValue<UserProfile>> {
  ProfileController(this.ref) : super(const AsyncLoading()) {
    _load();
  }

  final Ref ref;

  ProfileRepository get repository => ref.read(profileRepositoryProvider);

  Future<void> _load() async {
    final authState = ref.read(authStateProvider);

    if (!authState.isAuthenticated) {
      final fallback = profileFromAuthState();
      if (fallback != null) {
        state = AsyncData(fallback);
        return;
      }

      state = AsyncError(
        const AppException(
          type: AppExceptionType.unauthorized,
          message: 'You need to sign in again.',
        ),
        StackTrace.current,
      );
      return;
    }

    state = await AsyncValue.guard(() => repository.getProfile());
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

    state = const AsyncLoading();
    state = await AsyncValue.guard(() => repository.getProfile());
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

  final previousProfile =
      state is AsyncData<UserProfile>
          ? (state as AsyncData<UserProfile>).value
          : null;

  state = const AsyncLoading();

  try {
    final updatedProfile = await repository.updateProfile(
      username: username.trim(),
      email: email.trim(),
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      phoneNumber: normalize(phoneNumber),
      imageUrl: normalize(imageUrl),
    );

    state = AsyncData(updatedProfile);

    return true;
  } catch (error, stackTrace) {
    AppLogger.error(
      'Profile update failed.',
      tag: 'ProfileController',
      error: error,
      stackTrace: stackTrace,
    );

    if (previousProfile != null) {
      state = AsyncData(previousProfile);
    } else {
      state = AsyncError(error, stackTrace);
    }

    rethrow;
  }
}

Future<String> uploadProfileImage(String filePath) {
  return repository.uploadProfileImage(filePath);
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
    isBanned: false,
    createdAt: user.createdAt,
  );
  }

  String? normalize(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}