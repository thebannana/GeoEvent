import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/profile/models/user_profile.dart';
import '../../../shared/profile/providers/profile_providers.dart';

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, UserProfile>(
  ProfileController.new,
);

class ProfileController extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() async {
    return ref.read(profileRepositoryProvider).getProfile();
  }

  Future<void> refreshProfile() async {
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

class ProfileSettingsState {
  final bool notificationsEnabled;
  final bool marketingEmailsEnabled;
  final ThemeMode preferredThemeMode;

  const ProfileSettingsState({
    this.notificationsEnabled = true,
    this.marketingEmailsEnabled = false,
    this.preferredThemeMode = ThemeMode.system,
  });

  ProfileSettingsState copyWith({
    bool? notificationsEnabled,
    bool? marketingEmailsEnabled,
    ThemeMode? preferredThemeMode,
  }) {
    return ProfileSettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      marketingEmailsEnabled:
          marketingEmailsEnabled ?? this.marketingEmailsEnabled,
      preferredThemeMode: preferredThemeMode ?? this.preferredThemeMode,
    );
  }
}

final profileSettingsControllerProvider =
    NotifierProvider<ProfileSettingsController, ProfileSettingsState>(
  ProfileSettingsController.new,
);

class ProfileSettingsController extends Notifier<ProfileSettingsState> {
  @override
  ProfileSettingsState build() => const ProfileSettingsState();

  void setNotificationsEnabled(bool value) {
    state = state.copyWith(notificationsEnabled: value);
  }

  void setMarketingEmailsEnabled(bool value) {
    state = state.copyWith(marketingEmailsEnabled: value);
  }

  void setPreferredThemeMode(ThemeMode mode) {
    state = state.copyWith(preferredThemeMode: mode);
  }
}