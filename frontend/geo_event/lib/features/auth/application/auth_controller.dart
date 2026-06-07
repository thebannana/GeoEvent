import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/auth/models/auth_response.dart';
import '../../../shared/auth/models/auth_state.dart';
import '../../../shared/auth/models/login_request.dart';
import '../../../shared/auth/models/register_request.dart';
import '../../../shared/auth/providers/auth_providers.dart';

final authStateProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});

class AuthController extends StateNotifier<AuthState> {
  final Ref ref;

  AuthController(this.ref) : super(const AuthState.initial());

  Future<void> restoreSession() async {
    state = state.copyWith(isLoading: true, isInitialized: false);

    try {
      final storedState = await ref.read(authLocalStorageProvider).readSession();

      if (!storedState.hasRefreshToken) {
        state = const AuthState.initial().copyWith(isInitialized: true);
        return;
      }

      state = storedState.copyWith(
        isLoading: false,
        isInitialized: false,
      );

      final refreshed =
          await tryRefreshToken(storedState.refreshToken, setLoading: false);

      if (!refreshed) {
        state = const AuthState.initial().copyWith(isInitialized: true);
      }
    } catch (_) {
      state = const AuthState.initial().copyWith(isInitialized: true);
    }
  }

  Future<AuthResponse> login({
    required String emailOrUsername,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final response = await ref.read(authRepositoryProvider).login(
            LoginRequest(
              emailOrUsername: emailOrUsername.trim(),
              password: password,
              deviceInfo: 'flutter-android-emulator',
            ),
          );

      state = AuthState(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        expiresAt: response.expiresAt,
        user: response.user,
        isLoading: false,
        isInitialized: true,
      );

      return response;
    } catch (e) {
      state = state.copyWith(isLoading: false, isInitialized: true);
      rethrow;
    }
  }

Future<bool> register({
  required String username,
  required String email,
  required DateTime birthDate,
  required String phoneNumber,
  required String password,
  required String firstName,
  required String lastName,
  required bool consentGiven,
}) async {
  state = state.copyWith(isLoading: true);

  try {
    final response = await ref.read(authRepositoryProvider).register(
          RegisterRequest(
            username: username.trim().toLowerCase(),
            email: email.trim().toLowerCase(),
            birthDate: birthDate,
            phoneNumber: phoneNumber.trim(),
            consentGiven: consentGiven,
            consentVersion: '1.0',
            password: password,
            firstName: firstName.trim(),
            lastName: lastName.trim(),
          ),
        );

    state = AuthState(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
      expiresAt: response.expiresAt,
      user: response.user,
      isLoading: false,
      isInitialized: true,
    );

    return true;
  } catch (e) {
    state = state.copyWith(isLoading: false, isInitialized: true);
    rethrow;
  }
}

  Future<void> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true);

    try {
      await ref
          .read(authRepositoryProvider)
          .forgotPassword(email.trim().toLowerCase());

      state = state.copyWith(isLoading: false, isInitialized: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, isInitialized: true);
      rethrow;
    }
  }

  Future<bool> tryRefreshToken(
    String? overrideRefreshToken, {
    bool setLoading = false,
  }) async {
    final refreshToken = overrideRefreshToken ?? state.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      state = state.copyWith(isLoading: false, isInitialized: true);
      return false;
    }

    if (setLoading) {
      state = state.copyWith(isLoading: true);
    }

    try {
      final response =
          await ref.read(authRepositoryProvider).refresh(refreshToken);

      if (!response.hasTokens) {
        await ref.read(authRepositoryProvider).clearSession();
        state = const AuthState.initial().copyWith(isInitialized: true);
        return false;
      }

      state = state.copyWith(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        expiresAt: response.expiresAt,
        user: response.user,
        isLoading: false,
        isInitialized: true,
      );

      return true;
    } catch (_) {
      await ref.read(authRepositoryProvider).clearSession();
      state = const AuthState.initial().copyWith(isInitialized: true);
      return false;
    }
  }

  Future<void> logout() async {
    final refreshToken = state.refreshToken;

    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await ref.read(authRepositoryProvider).logout(refreshToken);
      } else {
        await ref.read(authRepositoryProvider).clearSession();
      }
    } catch (_) {
      await ref.read(authRepositoryProvider).clearSession();
    } finally {
      state = const AuthState.initial().copyWith(isInitialized: true);
    }
  }

  Future<void> clearSession() async {
    await ref.read(authRepositoryProvider).clearSession();
    state = const AuthState.initial().copyWith(isInitialized: true);
  }
}