import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../shared/auth/data/auth_api.dart';
import '../../../shared/auth/data/auth_repository.dart';
import '../../../shared/auth/models/auth_response.dart';
import '../../../shared/auth/models/auth_state.dart';
import '../../../shared/auth/models/login_request.dart';
import '../../../shared/auth/models/register_request.dart';

final authStateProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});

final baseDioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      validateStatus: (status) => status != null && status >= 200 && status < 300,
    ),
  );
});

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(baseDioProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(authApiProvider));
});

final authorizedDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: const {
        'Content-Type': 'application/json',
      },
      validateStatus: (status) => status != null && status >= 200 && status < 300,
    ),
  );

  dio.interceptors.add(
  InterceptorsWrapper(
    onRequest: (options, handler) {
      final token = ref.read(authStateProvider).accessToken;

      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }

      debugPrint('➡️ ${options.method} ${options.baseUrl}${options.path}');
      debugPrint('Headers: ${options.headers}');
      debugPrint('Query: ${options.queryParameters}');
      debugPrint('Body: ${options.data}');

      handler.next(options);
    },
    onResponse: (response, handler) {
      debugPrint(
        '✅ ${response.statusCode} ${response.requestOptions.method} '
        '${response.requestOptions.baseUrl}${response.requestOptions.path}',
      );
      debugPrint('Response: ${response.data}');
      handler.next(response);
    },
    onError: (error, handler) async {
      debugPrint(
        '❌ ${error.response?.statusCode} ${error.requestOptions.method} '
        '${error.requestOptions.baseUrl}${error.requestOptions.path}',
      );
      debugPrint('Query: ${error.requestOptions.queryParameters}');
      debugPrint('Body: ${error.requestOptions.data}');
      debugPrint('Response: ${error.response?.data}');

      if (error.response?.statusCode == 401) {
        final controller = ref.read(authStateProvider.notifier);
        final refreshed = await controller.tryRefreshToken();

        if (refreshed) {
          final retryToken = ref.read(authStateProvider).accessToken;
          final requestOptions = error.requestOptions;

          if (retryToken != null && retryToken.isNotEmpty) {
            requestOptions.headers['Authorization'] = 'Bearer $retryToken';
          }

          final retryResponse = await dio.fetch(requestOptions);
          return handler.resolve(retryResponse);
        }
      }

      handler.next(error);
    },
  ),
);

  return dio;
});

class AuthController extends StateNotifier<AuthState> {
  final Ref ref;

  AuthController(this.ref) : super(const AuthState.initial());

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<AuthResponse> login({
    required String emailOrUsername,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final response = await _repository.login(
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
      );

      return response;
    } catch (e) {
      state = state.copyWith(isLoading: false);
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
      final response = await _repository.register(
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

      if (response != null && response.hasTokens) {
        state = AuthState(
          accessToken: response.accessToken,
          refreshToken: response.refreshToken,
          expiresAt: response.expiresAt,
          user: response.user,
          isLoading: false,
        );
        return true;
      }

      state = state.copyWith(isLoading: false);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true);

    try {
      await _repository.forgotPassword(email.trim().toLowerCase());
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<bool> tryRefreshToken() async {
    final refreshToken = state.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    try {
      final response = await _repository.refresh(refreshToken);

      if (!response.hasTokens) {
        state = state.copyWith(clearTokens: true);
        return false;
      }

      state = state.copyWith(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        expiresAt: response.expiresAt,
        user: response.user,
      );

      return true;
    } catch (_) {
      state = state.copyWith(clearTokens: true);
      return false;
    }
  }

  Future<void> logout() async {
    final refreshToken = state.refreshToken;

    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _repository.logout(refreshToken);
      }
    } catch (_) {
    } finally {
      state = state.copyWith(clearTokens: true);
    }
  }
}