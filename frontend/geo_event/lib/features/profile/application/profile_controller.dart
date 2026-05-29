import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:geo_event/features/auth/application/auth_controller.dart';
import 'package:geo_event/shared/bookmarks/data/bookmark_api.dart';
import 'package:geo_event/shared/bookmarks/data/bookmark_repository.dart';
import 'package:geo_event/shared/profile/data/preferences_api.dart';
import 'package:geo_event/shared/profile/data/preferences_repository.dart';
import 'package:geo_event/shared/profile/data/profile_api.dart';
import 'package:geo_event/shared/profile/data/profile_repository.dart';
import 'package:geo_event/shared/profile/models/user_profile.dart';

// ── Profile ──────────────────────────────────────────────────────────────────

final profileApiProvider = Provider<ProfileApi>((ref) {
  return ProfileApi(ref.watch(authorizedDioProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(profileApiProvider));
});

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, UserProfile>(
  ProfileController.new,
);

class ProfileController extends AsyncNotifier<UserProfile> {
  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  @override
  Future<UserProfile> build() async {
    return _repository.getProfile();
  }

  Future<void> refreshProfile() async {
    final result = await AsyncValue.guard(_repository.getProfile);
    state = result;
  }

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? imageUrl,
    int? cityId,
  }) async {
    final result = await AsyncValue.guard(
      () => _repository.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        imageUrl: imageUrl,
        cityId: cityId,
      ),
    );
    state = result;
    return !result.hasError;
  }

  Future<void> revokeAllSessions() async {
    await _repository.revokeAllSessions();
  }
}

// ── Bookmarks ─────────────────────────────────────────────────────────────────

final bookmarkApiProvider = Provider<BookmarkApi>((ref) {
  return BookmarkApi(ref.watch(authorizedDioProvider));
});

final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  return BookmarkRepository(ref.watch(bookmarkApiProvider));
});

// ── Preferences ───────────────────────────────────────────────────────────────

final preferencesApiProvider = Provider<PreferencesApi>((ref) {
  return PreferencesApi(ref.watch(authorizedDioProvider));
});

final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  return PreferencesRepository(ref.watch(preferencesApiProvider));
});

// ── Profile Settings (local UI state only) ────────────────────────────────────

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

  void setNotificationsEnabled(bool value) =>
      state = state.copyWith(notificationsEnabled: value);

  void setMarketingEmailsEnabled(bool value) =>
      state = state.copyWith(marketingEmailsEnabled: value);

  void setPreferredThemeMode(ThemeMode mode) =>
      state = state.copyWith(preferredThemeMode: mode);
}