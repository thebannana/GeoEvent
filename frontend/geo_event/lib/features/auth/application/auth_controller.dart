import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/auth/data/auth_repository.dart';
import '../../../shared/auth/models/auth_response.dart';
import '../../../shared/auth/models/auth_state.dart';
import '../../../shared/auth/models/auth_user.dart';
import '../../../shared/auth/models/login_request.dart';
import '../../../shared/auth/models/register_request.dart';
import '../../../shared/auth/models/reset_password_request.dart';
import '../../../shared/auth/providers/auth_providers.dart';
import '../../../shared/events/providers/event_refresh_providers.dart';
import '../../profile/application/preferences_controller.dart';
import '../../search/application/search_controller.dart';

final authStateProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});

final sessionUserIdProvider = Provider<int?>((ref) {
  return ref.watch(authStateProvider).user?.userId;
});

class AuthController extends StateNotifier<AuthState> {
  AuthController(this.ref) : super(const AuthState.initial());

  final Ref ref;

  static const String _defaultDeviceInfo = 'flutter-app';
  static const String _defaultConsentVersion = '1.0';

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  void _refreshEventMap() {
    ref.read(eventMapRefreshProvider.notifier).state++;
  }

  Future<void> restoreSession() async {
    _setLoading(true, initialized: false);

    try {
      final restored = await _repository.restoreSession();

      if (!restored.hasRefreshToken) {
        state = const AuthState.unauthenticated(isInitialized: true);
        return;
      }

      state = restored.copyWith(
        isLoading: false,
        isInitialized: true,
      );

      final refreshed = await refreshSession(
        overrideRefreshToken: restored.refreshToken,
        preserveUser: restored.user,
        setLoading: false,
      );

      if (!refreshed) {
        state = const AuthState.unauthenticated(isInitialized: true);
      }
    } catch (_) {
      state = const AuthState.unauthenticated(isInitialized: true);
    }
  }

  Future<AuthResponse> login({
    required String emailOrUsername,
    required String password,
  }) async {
    _setLoading(true);

    try {
      final response = await _repository.login(
        LoginRequest(
          emailOrUsername: emailOrUsername.trim(),
          password: password,
          deviceInfo: _defaultDeviceInfo,
        ),
      );

      await setAuthenticated(response, preserveUser: response.user);
      _refreshEventMap();

      return response;
    } catch (_) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<AuthResponse> register({
    required String username,
    required String email,
    required DateTime birthDate,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
    required String firstName,
    required String lastName,
    required bool consentGiven,
  }) async {
    _setLoading(true);

    try {
      final response = await _repository.register(
        RegisterRequest(
          username: username.trim().toLowerCase(),
          email: email.trim().toLowerCase(),
          birthDate: birthDate,
          phoneNumber: phoneNumber.trim(),
          consentGiven: consentGiven,
          consentVersion: _defaultConsentVersion,
          password: password,
          confirmPassword: confirmPassword,
          firstName: firstName.trim(),
          lastName: lastName.trim(),
        ),
      );

      await setAuthenticated(response, preserveUser: response.user);
      ref.invalidate(preferencesControllerProvider);
      _refreshEventMap();

      return response;
    } catch (_) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> forgotPassword(String email) async {
    _setLoading(true);

    try {
      await _repository.forgotPassword(email.trim().toLowerCase());
      _setLoading(false);
    } catch (_) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _setLoading(true);

    try {
      await _repository.resetPassword(
        ResetPasswordRequest(
          email: email.trim().toLowerCase(),
          token: token.trim(),
          newPassword: newPassword,
          confirmPassword: confirmPassword,
        ),
      );
      _setLoading(false);
    } catch (_) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<bool> refreshSession({
    String? overrideRefreshToken,
    AuthUser? preserveUser,
    bool setLoading = false,
  }) async {
    final refreshToken = overrideRefreshToken ?? state.refreshToken;
    final fallbackUser = preserveUser ?? state.user;

    if (refreshToken == null || refreshToken.trim().isEmpty) {
      await _repository.clearSession();
      state = const AuthState.unauthenticated(isInitialized: true);
      return false;
    }

    if (setLoading) {
      _setLoading(true);
    }

    try {
      final response = await _repository.refresh(refreshToken);

      if (!response.hasTokens) {
        await _repository.clearSession();
        state = const AuthState.unauthenticated(isInitialized: true);
        return false;
      }

      await setAuthenticated(response, preserveUser: fallbackUser);
      ref.invalidate(preferencesControllerProvider);
      return true;
    } catch (_) {
      await _repository.clearSession();
      state = const AuthState.unauthenticated(isInitialized: true);
      return false;
    }
  }

  Future<void> setAuthenticated(
    AuthResponse response, {
    AuthUser? preserveUser,
  }) async {
    final effectiveUser = response.user ?? preserveUser ?? state.user;

    if (effectiveUser == null) {
      await _repository.clearSession();
      state = const AuthState.unauthenticated(isInitialized: true);
      return;
    }

    state = AuthState(
      accessToken: response.accessToken.trim(),
      refreshToken: response.refreshToken.trim(),
      expiresAt: response.expiresAt,
      user: effectiveUser,
      isLoading: false,
      isInitialized: true,
    );
  }

Future<void> logout() async {
  final refreshToken = state.refreshToken;

  try {
    if (refreshToken != null &&
        refreshToken.trim().isNotEmpty) {
      await _repository.logout(refreshToken);
    } else {
      await _repository.clearSession();
    }
  } catch (_) {
    await _repository.clearSession();
  } finally {
    ref
        .read(searchControllerProvider.notifier)
        .reset();

    state = const AuthState.unauthenticated(
      isInitialized: true,
    );

    _refreshEventMap();
  }
}

  Future<void> clearSession() async {
    await _repository.clearSession();

    ref
        .read(searchControllerProvider.notifier)
        .reset();

    state = const AuthState.unauthenticated(
      isInitialized: true,
    );

    _refreshEventMap();
  }

  void _setLoading(bool value, {bool initialized = true}) {
    state = state.copyWith(
      isLoading: value,
      isInitialized: initialized,
    );
  }
}